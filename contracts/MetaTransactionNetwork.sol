// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title MetaTransaction Network
 * @notice A decentralized network that enables gasless transactions through trusted relayers.
 *         Users can sign a message, and relayers can submit transactions on their behalf.
 */
contract Project {
    address public admin;
    mapping(address => uint256) public nonces;
    mapping(address => bool) public relayers;

    event RelayerAdded(address indexed relayer);
    event RelayerRemoved(address indexed relayer);
    event MetaTransactionExecuted(address indexed user, address indexed relayer, bytes functionSignature);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    /**
     * @notice Add a trusted relayer to the network
     * @param _relayer Address of the relayer
     */
    function addRelayer(address _relayer) external onlyAdmin {
        relayers[_relayer] = true;
        emit RelayerAdded(_relayer);
    }

    /**
     * @notice Remove a relayer from the trusted list
     * @param _relayer Address of the relayer
     */
    function removeRelayer(address _relayer) external onlyAdmin {
        relayers[_relayer] = false;
        emit RelayerRemoved(_relayer);
    }

    /**
     * @notice Execute a meta-transaction signed by the user
     * @param user Address of the user
     * @param functionSignature Encoded function data to execute
     * @param sigR, sigS, sigV ECDSA signature parts
     */
    function executeMetaTransaction(
        address user,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external returns (bytes memory) {
        require(relayers[msg.sender], "Only trusted relayer can execute");

        bytes32 metaTxHash = getMessageHash(user, functionSignature, nonces[user]);
        address signer = ecrecover(toEthSignedMessageHash(metaTxHash), sigV, sigR, sigS);
        require(signer == user, "Invalid signature");

        nonces[user]++;

        (bool success, bytes memory returnData) = address(this).call(abi.encodePacked(functionSignature, user));
        require(success, "Meta-transaction failed");

        emit MetaTransactionExecuted(user, msg.sender, functionSignature);
        return returnData;
    }

    /**
     * @notice Generate message hash for signature
     */
    function getMessageHash(address user, bytes memory functionSignature, uint256 nonce)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(user, functionSignature, nonce));
    }

    /**
     * @notice Convert hash to Ethereum Signed Message format
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @notice Get the current nonce of a user
     */
    function getNonce(address user) external view returns (uint256) {
        return nonces[user];
    }
}
// 
End
// 
