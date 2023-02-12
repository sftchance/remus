// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

/// @dev Core dependencies.
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/// @notice Minimal transaction forwarder to be inhereted from that enables the minting of a Badge
///         to the source of the transaction upon the completion of Forwarding.
/// @dev To enable the use of a Badger Oragnization, the contract must be made a delegate of the Badge
///      that is being minted or be the owner of the Organization.
/// @dev Do not use this in production without adding an expiration to the signature as your auditors
///      will not be happy and you will be paying for another deployment.
/// @author Remus (https://github.com/nftchance/remus/blob/main/src/metatx/BadgingForwarder.sol)
abstract contract BadgingForwarder is EIP712 {
    using ECDSA for bytes32;

    ////////////////////////////////////////////////////////
    ///                      SCHEMA                      ///
    ////////////////////////////////////////////////////////

    /// @dev Schema of the ForwardRequest.
    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    /// @dev Schema of the Badge that will be minted.
    struct Badge {
        Badger badgerOrganization;
        uint256 id;
        uint256 amount;
    }

    /// @dev Typehash of the ForwardRequest used to validate the signature.
    bytes32 private constant _TYPEHASH =
        keccak256(
            "ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)"
        );

    ////////////////////////////////////////////////////////
    ///                      STATE                       ///
    ////////////////////////////////////////////////////////

    /// @dev The badge that is minted upon forwarding.
    Badge public badge;

    /// @dev The nonces that have been used by the forwarder.
    mapping(address => uint256) private _nonces;

    ////////////////////////////////////////////////////////
    ///                   CONSTRUCTOR                    ///
    ////////////////////////////////////////////////////////

    constructor() EIP712("BadgingFowarder", "0.0.1") {}

    ////////////////////////////////////////////////////////
    ///                    SETTERS                       ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Execute a transaction that has been signed for.
     * @notice We explicitly trigger invalid opcode to consume all gas and bubble-up the effects, since
     *         neither revert or assert consume all gas since Solidity 0.8.0
     * @param req The request to execute.
     * @param signature The signature of the request.
     * @return True if the transaction was successful, false otherwise.
     */
    function execute(ForwardRequest calldata req, bytes calldata signature)
        public
        payable
        returns (bool, bytes memory)
    {
        /// @dev Verify that the transaction is valid.
        require(
            verify(req, signature),
            "MinimalForwarder: signature does not match request"
        );

        /// @dev Account for gas needed to mint the badge.
        uint256 postProcessingGas = 80000;

        /// @dev Account for gas needed to refund the surplus value.
        if (req.value > 0) postProcessingGas += 40000;

        /// @dev Validate that the relayer has sent enough gas for the call.
        require(
            gasleft() * 63 / 64 >= req.gas + postProcessingGas,
            "BadgingForwarder: not enough gas to execute transaction."
        );

        /// @dev Increment the nonce.
        _nonces[req.from] = req.nonce + 1;

        /// @dev Make the call.
        (bool success, bytes memory returndata) = req.to.call{
            gas: req.gas,
            value: req.value
        }(abi.encodePacked(req.data, req.from));

        /// @dev Determine if there is money to refund.
        if (req.value > 0 && address(this).balance > 0) {
            /// @dev Refund the surplus value to the source of the transaction.
            /// @notice Expected to be an EOA due to signed transaction.
            payable(req.from).transfer(address(this).balance);
        }

        /// @dev On successful call, mint the badge.
        if (success) {
            /// @dev Mint the badge to the source of the transaction.
            badge.badgerOrganization.leaderMint(
                req.from,
                badge.id,
                badge.amount
            );
        }

        /// @dev Return the success and returndata.
        return (success, returndata);
    }

    ////////////////////////////////////////////////////////
    ///                    GETTERS                       ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Returns the nonce of the given address.
     * @param _user The address to get the nonce of.
     * @return The nonce of the given address.
     */
    function getNonce(address _user) public view returns (uint256) {
        return _nonces[_user];
    }

    /**
     * @dev Verifies that the signature is valid and the nonce is correct.
     * @param req The ForwardRequest to verify.
     * @param signature The signature to verify.
     * @return True if the signature is valid and the nonce is correct, false otherwise.
     */
    function verify(ForwardRequest calldata req, bytes calldata signature)
        public
        view
        returns (bool)
    {
        /// @dev Recover the signer of the message.
        /// @notice Expected to the be the source of the transaction.
        address signer = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _TYPEHASH,
                    req.from,
                    req.to,
                    req.value,
                    req.gas,
                    req.nonce,
                    keccak256(req.data)
                )
            )
        ).recover(signature);

        /// @dev Verify that the signer is the source of the transaction and the nonce is correct.
        return _nonces[req.from] == req.nonce && signer == req.from;
    }

    ////////////////////////////////////////////////////////
    ///                 INTERNAL SETTERS                 ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Sets the badge that is minted upon forwarding.
     * @param _badge The badge that is minted upon forwarding.
     */
    function _setBadge(Badge calldata _badge) internal {
        badge = _badge;
    }
}

interface Badger {
    /**
     * @dev Mints a badge to the given address.
     * @param _to The address to mint the badge to.
     * @param _id The id of the badge to mint.
     * @param _amount The amount of the badge to mint.
     */
    function leaderMint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external;
}
