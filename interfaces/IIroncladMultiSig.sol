// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;
interface IIroncladMultiSig {
    function submitTransaction(address destination, uint256 value, bytes calldata data) external returns (uint256 transactionId);
    function confirmTransaction(uint256 transactionId) external;
    function executeTransaction(uint256 transactionId) external;
}
