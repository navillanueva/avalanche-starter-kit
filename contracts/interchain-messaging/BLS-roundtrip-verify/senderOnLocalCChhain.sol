// (c) 2023, Ava Labs, Inc. All rights reserved.
// See the file LICENSE for licensing terms.

// SPDX-License-Identifier: Ecosystem

pragma solidity ^0.8.18;

import "@teleporter/ITeleporterMessenger.sol";
import "@teleporter/ITeleporterReceiver.sol";
import "./VerifierActions.sol";

contract SenderOnLocalCChain is ITeleporterReceiver {
    ITeleporterMessenger public immutable messenger = ITeleporterMessenger(0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf);

    struct VerificationResult {
        bool isSingle;
        bool verified;
    }

    VerificationResult public result;

    function sendSingleVerifyMessage(
        address destinationAddress,
        bytes calldata publicKey,
        bytes calldata signature,
        string calldata message
    ) external {
        messenger.sendCrossChainMessage(
            TeleporterMessageInput({
                // blockchainID of Nico layer 1
                destinationBlockchainID: 0x5a5a8cd30d69c017c454fbadd0c0ebc6c763b0017070b7a38aa227cd616ecc34,
                destinationAddress: destinationAddress,
                feeInfo: TeleporterFeeInfo({feeTokenAddress: address(0), amount: 0}),
                requiredGasLimit: 200000,
                allowedRelayerAddresses: new address[](0),
                message: encodeSingleVerify(publicKey, signature, message)
            })
        );
    }

    // This is kind of dumb since the Verify function on the layer one takes in the same params for single or aggregated values
    // so we could just use one sendMessage, but for the case of showcasing how multiple functions would work
    function sendAggregateVerifyMessage(
        address destinationAddress,
        bytes[] calldata publicKeys,
        bytes[] calldata signatures,
        string calldata message
    ) external {
        messenger.sendCrossChainMessage(
            TeleporterMessageInput({
                // blockchainID of Nico layer 1
                destinationBlockchainID: 0x5a5a8cd30d69c017c454fbadd0c0ebc6c763b0017070b7a38aa227cd616ecc34,
                destinationAddress: destinationAddress,
                feeInfo: TeleporterFeeInfo({feeTokenAddress: address(0), amount: 0}),
                requiredGasLimit: 200000,
                allowedRelayerAddresses: new address[](0),
                message: encodeAggregateVerify(publicKeys, signatures, message)
            })
        );
    }

    function receiveTeleporterMessage(bytes32, address, bytes calldata message) external {
        // Only the Teleporter receiver can deliver a message.
        require(msg.sender == address(messenger), "SenderOnCChain: unauthorized TeleporterMessenger");

        (bool isSingle, bool verified) = abi.decode(message, (bool, bool));

        result = VerificationResult(isSingle, verified);
    }

    function encodeSingleVerify(bytes calldata publicKey, bytes calldata signature, string calldata message)
        public
        pure
        returns (bytes memory)
    {
        bytes memory paramsData = abi.encode(publicKey, signature, message);
        return abi.encode(VerifierAction.singleVerify, paramsData);
    }

    function encodeAggregateVerify(bytes[] calldata publicKeys, bytes[] calldata signatures, string calldata message)
        public
        pure
        returns (bytes memory)
    {
        bytes memory paramsData = abi.encode(publicKeys, signatures, message);
        return abi.encode(VerifierAction.aggregateVerify, paramsData);
    }
}
