// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Base64} from '../../lib/openzeppelin-contracts/contracts/utils/Base64.sol';
import {Strings} from '../../lib/openzeppelin-contracts/contracts/utils/Strings.sol';
import {LibDN404} from './LibDN404.sol';

library LibTokenURI {
    struct JSONPrimecoreData {
        string tokenId;
        string name;
        string rarity;
        string luck;
        string production;
        string elementSlot1;
        string elementSlot2;
        string elementSlot3;
    }

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
                Strings.toString(tokenId),
                'Primecore',
                getRarityName(rarityTier),
                Strings.toString(luck),
                Strings.toString(prodType),
                getElementName(elementSlot1),
                getElementName(elementSlot2),
                getElementName(elementSlot3)
            );
    }

    function generateTokenURI(uint256 tokenId) internal view returns (string memory) {
        JSONPrimecoreData memory primecoreData = getJSONReadyPrimecoreData(tokenId);
        bytes memory json = abi.encodePacked(
            '{"token_id":"',
            primecoreData.tokenId,
            '","name":"#',
            primecoreData.name,
            '","image":"',
            LibDN404._getImageURI(tokenId),
            '","version":"1","attributes":[{"trait_type":"Rarity","value":"',
            primecoreData.rarity,
            '"},{"trait_type":"Luck","display_type":"number","value":"',
            primecoreData.luck,
            '"},{"trait_type":"Production","display_type":"number","value":"',
            primecoreData.production,
            '"},{"trait_type":"Element 1","value":"',
            primecoreData.elementSlot1,
            '"},{"trait_type":"Element 2","value":"',
            primecoreData.elementSlot2,
            '"},{"trait_type":"Element 3","value":"',
            primecoreData.elementSlot3,
            '"}]}'
        );

        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(json)));
    }

    function getElementName(uint8 element) internal pure returns (string memory) {
        if (element == 1) {
            return 'Fire';
        }
        if (element == 2) {
            return 'Water';
        }
        if (element == 3) {
            return 'Earth';
        }
        return 'None';
    }

    function getRarityName(uint8 rarity) internal pure returns (string memory) {
        if (rarity == 1) {
            return 'Common';
        }
        if (rarity == 2) {
            return 'Uncommon';
        }
        if (rarity == 3) {
            return 'Epic';
        }
        if (rarity == 4) {
            return 'Legendary';
        }
        if (rarity == 5) {
            return 'Mythic';
        }
        return 'None';
    }
}
