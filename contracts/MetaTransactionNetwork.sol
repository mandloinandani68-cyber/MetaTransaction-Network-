@title MetaTransactionNetwork - Lightweight meta-transaction execution layer
/@notice Execute a transaction signed off-chain by the user
    /@param functionData encoded function call data to be executed
    /prevent replay attacks

        @notice Get current nonce for user (used in signing)
    function getNonce(address user) external view returns (uint256) {
        return nonces[user];
    }

    /@dev Recover signer from signature
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
// 
update
// 
