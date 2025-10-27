// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title MetaTransactionNetwork - Lightweight meta-transaction execution layer
/// @notice Enables relayers to submit transactions on behalf of users with signature verification

contract MetaTransactionNetwork {
    mapping(address => uint256) private nonces;

    event MetaTransactionExecuted(address user, address relayer, bytes functionData);

    /// @notice Execute a transaction signed off-chain by the user
    /// @param user address of the user who signed the transaction
    /// @param functionData encoded function call data to be executed
    /// @param signature user's ECDSA signature (r,s,v packed in bytes)
    function executeMetaTransaction(
        address user,
        bytes calldata functionData,
        bytes calldata signature
    ) external {
        bytes32 messageHash = getMessageHash(user, functionData, nonces[user]);
        address signer = recoverSigner(messageHash, signature);
        require(signer == user, "Invalid signature");

        nonces[user]++; // prevent replay attacks

        // low-level call executes the given function data
        (bool success, ) = address(this).call(functionData);
        require(success, "Function call failed");

        emit MetaTransactionExecuted(user, msg.sender, functionData);
    }

    /// @notice Get current nonce for user (used in signing)
    function getNonce(address user) external view returns (uint256) {
        return nonces[user];
    }

    /// @dev Generate hash of message to sign
    function getMessageHash(
        address user,
        bytes calldata functionData,
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(user, functionData, nonce));
    }

    /// @dev Recover signer from signature
    function recoverSigner(bytes32 hash, bytes calldata signature) internal pure returns (address) {
        bytes32 ethSignedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(ethSignedHash, v, r, s);
    }

    /// @dev Split bytes signature into r, s, v
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(sig.length == 65, "Invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}
