// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title LibTokenURI
/// @author Shiva (shiva.shanmuganathan@laguna.games)
/// @notice Library for generating token URIs for Primecore tokens

import {Base64} from '../../lib/openzeppelin-contracts/contracts/utils/Base64.sol';
import {Strings} from '../../lib/openzeppelin-contracts/contracts/utils/Strings.sol';
import {LibDN404} from './LibDN404.sol';

library LibTokenURI {
    /// @notice Struct for storing Primecore data in JSON format
    struct JSONPrimecoreData {
        string name;
        string tokenId;
        string production;
        string rarity;
        string elementSlot1;
        string elementSlot2;
        string elementSlot3;
        string luck;
    }

    /// @notice Gets the JSON ready Primecore data
    /// @param tokenId The token ID.
    /// @return The JSON ready Primecore data.
    function getJSONReadyPrimecoreData(uint256 tokenId) internal view returns (JSONPrimecoreData memory) {
        (
            uint8 rarityTier,
            uint16 luck,
            uint8 prodType,
            uint8 elementSlot1,
            uint8 elementSlot2,
            uint8 elementSlot3
        ) = LibDN404.getPrimecoreData(tokenId);
        return
            JSONPrimecoreData(
                string.concat('Prime Core #', Strings.toString(tokenId)),
                Strings.toString(tokenId),
                getProductionName(prodType),
                getRarityName(rarityTier),
                getElementName(elementSlot1),
                getElementName(elementSlot2),
                getElementName(elementSlot3),
                Strings.toString(luck)
            );
    }

    /// @notice Generates the token URI for a Primecore token
    /// @param tokenId The token ID.
    /// @return The token URI.
    function generateTokenURI(uint256 tokenId) internal view returns (string memory) {
        (
            uint8 rarityTier,
            uint16 luck,
            uint8 prodType,
            uint8 elementSlot1,
            uint8 elementSlot2,
            uint8 elementSlot3
        ) = LibDN404.getPrimecoreData(tokenId);

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        abi.encodePacked(
                            '{"token_id":"',
                            Strings.toString(tokenId),
                            '","name":"Prime Core #',
                            Strings.toString(tokenId),
                            '","image":"',
                            _getImageURI(tokenId),
                            '","version":"1","attributes":',
                            _buildAttributes(prodType, rarityTier, elementSlot1, elementSlot2, elementSlot3, luck),
                            '}'
                        )
                    )
                )
            );
    }

    /// @notice Builds the attributes JSON array
    /// @dev Only includes element slots 2 and 3 if they are non-zero
    function _buildAttributes(
        uint8 prodType,
        uint8 rarityTier,
        uint8 elementSlot1,
        uint8 elementSlot2,
        uint8 elementSlot3,
        uint16 luck
    ) internal pure returns (bytes memory) {
        // Initialize with required attributes
        bytes memory attributes = abi.encodePacked(
            '[{"trait_type":"Production","value":"',
            getProductionName(prodType),
            '"},{"trait_type":"Rarity","value":"',
            getRarityName(rarityTier),
            '"},{"trait_type":"Element 1","value":"',
            getElementName(elementSlot1),
            '"}'
        );

        // Add optional elements
        if (elementSlot2 != 0) {
            attributes = abi.encodePacked(
                attributes,
                ',{"trait_type":"Element 2","value":"',
                getElementName(elementSlot2),
                '"}'
            );
        }

        if (elementSlot3 != 0) {
            attributes = abi.encodePacked(
                attributes,
                ',{"trait_type":"Element 3","value":"',
                getElementName(elementSlot3),
                '"}'
            );
        }

        // Add luck and close array
        return
            abi.encodePacked(
                attributes,
                ',{"trait_type":"Luck","display_type":"number","value":',
                Strings.toString(luck),
                '}]'
            );
    }

    /// @notice Gets the element name from the element ID
    /// @param element The element ID.
    /// @return The element name.
    function getElementName(uint8 element) internal pure returns (string memory) {
        if (element == 1) {
            return 'fire';
        }
        if (element == 2) {
            return 'water';
        }
        if (element == 3) {
            return 'earth';
        }
        return 'blank';
    }

    /// @notice Gets the rarity name from the rarity ID
    /// @param rarity The rarity ID.
    /// @return The rarity name.
    function getRarityName(uint8 rarity) internal pure returns (string memory) {
        if (rarity == 1) {
            return 'common';
        }
        if (rarity == 2) {
            return 'uncommon';
        }
        if (rarity == 3) {
            return 'rare';
        }
        if (rarity == 4) {
            return 'legendary';
        }
        if (rarity == 5) {
            return 'mythic';
        }
        return 'blank';
    }

    /// @notice Gets the production name from the production ID
    /// @param production The production ID.
    /// @return The production name.
    function getProductionName(uint8 production) internal pure returns (string memory) {
        if (production == 1) {
            return 'hydrosteel';
        }
        if (production == 2) {
            return 'terraglass';
        }
        if (production == 3) {
            return 'firestone';
        }
        if (production == 4) {
            return 'kronosite';
        }
        if (production == 5) {
            return 'celestium';
        }
        return 'blank';
    }

    function _getImageURI(uint256 tokenId) internal view returns (string memory) {
        JSONPrimecoreData memory primecoreData = getJSONReadyPrimecoreData(tokenId);
        return
            string(
                abi.encodePacked(
                    LibDN404._getBaseURI(),
                    primecoreData.production,
                    '-',
                    primecoreData.rarity,
                    '_',
                    primecoreData.elementSlot1,
                    '_',
                    primecoreData.elementSlot2,
                    '_',
                    primecoreData.elementSlot3,
                    '.gif'
                )
            );
    }
}
