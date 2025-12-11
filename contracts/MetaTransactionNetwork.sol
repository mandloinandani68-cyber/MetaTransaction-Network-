// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract MetaTransactionNetwork {
    address public owner;

    // Track executed meta-transactions to prevent replay attacks
    mapping(bytes32 => bool) public executedTx;

    event MetaTransactionExecuted(
        address indexed user,
        address indexed relayer,
        address token,
        address to,
        uint256 amount,
        bytes32 txHash
    );

    constructor() {
        owner = msg.sender;
    }

    struct MetaTx {
        address user;
        address token;
        address to;
        uint256 amount;
        uint256 nonce;
    }

    /// @notice Execute a meta-transaction signed off-chain by the user
    function executeMetaTransaction(
        MetaTx calldata metaTx,
        bytes calldata signature
    ) external returns (bool) {

        bytes32 txHash = getTransactionHash(metaTx);
        require(!executedTx[txHash], "MetaTx already executed");

        require(verifySignature(metaTx.user, txHash, signature), "Invalid signature");

        executedTx[txHash] = true;

        require(
            IERC20(metaTx.token).transferFrom(metaTx.user, metaTx.to, metaTx.amount),
            "Token transfer failed"
        );

        emit MetaTransactionExecuted(
            metaTx.user,
            msg.sender,
            metaTx.token,
            metaTx.to,
            metaTx.amount,
            txHash
        );

        return true;
    }

    /// @notice Build the hash for the meta-transaction
    function getTransactionHash(
        MetaTx calldata metaTx
    ) public pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                metaTx.user,
                metaTx.token,
                metaTx.to,
                metaTx.amount,
                metaTx.nonce
            )
        );
    }

    /// @notice Verify the signature using ECDSA
    function verifySignature(
        address signer,
        bytes32 txHash,
        bytes memory signature
    ) internal pure returns (bool) {

        bytes32 ethSignedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", txHash)
        );

        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        return signer == ecrecover(ethSignedHash, v, r, s);
    }

    /// @notice Split signature into r, s, v
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
