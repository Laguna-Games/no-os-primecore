// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title LibRNG
/// @author Shiva (shiva.shanmuganathan@laguna.games)
/// @notice Library for generating pseudo-random numbers

interface IArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);
}

/// @custom:storage-location dn404:NeoOlympus.RNG.storage
library LibRNG {
    // Storage position using a unique identifier
    bytes32 constant RNG_STORAGE_POSITION = keccak256('NeoOlympus.RNG.storage');

    struct RNGStorage {
        uint256 rngNonce;
    }

    function getRuntimeRNG() internal returns (uint256) {
        return getRuntimeRNG(type(uint256).max);
    }

    /// @notice Generates a pseudo-random integer. This is cheaper than VRF but less secure.
    /// The rngNonce seed should be rotated by VRF before using this pRNG.
    /// @custom:see https://www.geeksforgeeks.org/random-number-generator-in-solidity-using-keccak256/
    /// @custom:see https://docs.chain.link/docs/chainlink-vrf-best-practices/
    /// @param _modulus The range of the response (exclusive)
    /// @return Random integer in the range of [0-_modulus)
    function getRuntimeRNG(uint256 _modulus) internal returns (uint256) {
        RNGStorage storage rs = rngStorage();

        // Increment nonce
        unchecked {
            rs.rngNonce++;
        }

        // Generate random number using multiple sources of entropy
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(block.prevrandao, block.timestamp, block.number, rs.rngNonce, msg.sender))
        );

        // If modulus is provided, constrain the range
        if (_modulus > 0) {
            return randomNumber % _modulus;
        }

        return randomNumber;
    }

    /// @notice Expands a seed into a random number.
    /// @param _modulus The range of the response (exclusive)
    /// @param _seed The seed to expand
    /// @param _salt The salt to expand
    /// @return Random integer in the range of [0-_modulus)
    function expand(uint256 _modulus, uint256 _seed, uint256 _salt) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(_seed, _salt))) % _modulus;
    }

    /// @notice Returns the storage position for the RNG.
    function rngStorage() internal pure returns (RNGStorage storage rs) {
        bytes32 position = RNG_STORAGE_POSITION;
        assembly {
            rs.slot := position
        }
    }
}
