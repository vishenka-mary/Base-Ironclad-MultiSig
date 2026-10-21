// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract IroncladMultiSig {
    struct Transaction {
        address payable destination;
        uint256 value;
        string memo;
        bool executed;
        uint256 confirmationCount;
    }

    address payable public immutable primaryAdmin;
    string public vaultTag;
    uint256 public requiredConfirmations;
    uint256 public transactionCount;

    mapping(address => bool) public isSigner;
    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    event DepositReceived(address indexed sender, uint256 amount);
    event TransactionSubmitted(uint256 indexed txId, address indexed destination, uint256 value);
    event TransactionConfirmed(uint256 indexed txId, address indexed signer);
    event ConfirmationRevoked(uint256 indexed txId, address indexed signer);
    event TransactionExecuted(uint256 indexed txId);
    event RequirementChanged(uint256 newRequired);
    event VaultTagUpdated(string newTag);
    event EmergencyFundsEvacuated(address indexed admin, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == primaryAdmin, "IroncladMultiSig: Caller is not admin");
        _;
    }

    modifier onlySigner() {
        require(isSigner[msg.sender], "IroncladMultiSig: Caller is not signer");
        _;
    }

    constructor() {
        primaryAdmin = payable(msg.sender);
        isSigner[msg.sender] = true;
        requiredConfirmations = 1;
        vaultTag = "Ironclad Base Treasury v1";
    }

    // 1. Пополнение казны контракта
    function depositToTreasury() external payable {
        require(msg.value > 0, "IroncladMultiSig: Deposit must be positive");
        emit DepositReceived(msg.sender, msg.value);
    }

    // 2. Создание заявки на выплату
    function submitTransaction(
        address payable destination,
        uint256 value,
        string calldata memo
    ) external onlySigner returns (uint256) {
        require(destination != address(0), "IroncladMultiSig: Zero destination");

        transactionCount++;
        transactions[transactionCount] = Transaction({
            destination: destination,
            value: value,
            memo: memo,
            executed: false,
            confirmationCount: 0
        });

        emit TransactionSubmitted(transactionCount, destination, value);
        return transactionCount;
    }

    // 3. Подтверждение транзакции подписантом
    function confirmTransaction(uint256 txId) external onlySigner {
        require(txId > 0 && txId <= transactionCount, "IroncladMultiSig: Invalid tx ID");
        require(!transactions[txId].executed, "IroncladMultiSig: Tx already executed");
        require(!isConfirmed[txId][msg.sender], "IroncladMultiSig: Already confirmed");

        isConfirmed[txId][msg.sender] = true;
        transactions[txId].confirmationCount++;

        emit TransactionConfirmed(txId, msg.sender);
    }

    // 4. Отзыв подтверждения
    function revokeConfirmation(uint256 txId) external onlySigner {
        require(txId > 0 && txId <= transactionCount, "IroncladMultiSig: Invalid tx ID");
        require(!transactions[txId].executed, "IroncladMultiSig: Tx already executed");
        require(isConfirmed[txId][msg.sender], "IroncladMultiSig: Not confirmed");

        isConfirmed[txId][msg.sender] = false;
        transactions[txId].confirmationCount--;

        emit ConfirmationRevoked(txId, msg.sender);
    }

    // 5. Исполнение подтвержденной транзакции
    function executeTransaction(uint256 txId) external onlySigner {
        Transaction storage txn = transactions[txId];
        require(txId > 0 && txId <= transactionCount, "IroncladMultiSig: Invalid tx ID");
        require(!txn.executed, "IroncladMultiSig: Already executed");
        require(txn.confirmationCount >= requiredConfirmations, "IroncladMultiSig: Quorum not met");
        require(address(this).balance >= txn.value, "IroncladMultiSig: Insufficient balance");

        txn.executed = true;
        (bool sent, ) = txn.destination.call{value: txn.value}("");
        require(sent, "IroncladMultiSig: Transfer failed");

        emit TransactionExecuted(txId);
    }

    // 6. Изменение требуемого кворума
    function changeRequirement(uint256 newRequired) external onlyAdmin {
        require(newRequired > 0 && newRequired <= 5, "IroncladMultiSig: Invalid requirement range");
        requiredConfirmations = newRequired;
        emit RequirementChanged(newRequired);
    }

    // 7. Обновление публичного тега
    function updateVaultTag(string calldata newTag) external onlyAdmin {
        require(bytes(newTag).length > 0, "IroncladMultiSig: Empty tag");
        vaultTag = newTag;
        emit VaultTagUpdated(newTag);
    }

    // 8. Аварийная эвакуация остатка средств администратором
    function emergencyWithdrawal() external onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "IroncladMultiSig: No balance to sweep");

        (bool sent, ) = primaryAdmin.call{value: balance}("");
        require(sent, "IroncladMultiSig: Sweep failed");

        emit EmergencyFundsEvacuated(primaryAdmin, balance);
    }

    // Чтение информации о транзакции
    function getTransaction(uint256 txId) external view returns (
        address destination,
        uint256 value,
        string memory memo,
        bool executed,
        uint256 confirmationCount
    ) {
        Transaction memory t = transactions[txId];
        return (t.destination, t.value, t.memo, t.executed, t.confirmationCount);
    }
}