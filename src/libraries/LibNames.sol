// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/// @custom:storage-location erc7201:NeoOlympus.Names.storage
library LibNames {
    bytes32 constant NAMES_STORAGE_POSITION =
        keccak256(
            abi.encode(uint256(keccak256("NeoOlympus.Names.storage")) - 1)
        ) & ~bytes32(uint256(0xff));
    struct NamesStorage {
        // nameIndex -> name string
        mapping(uint256 => string) firstNamesList;
        mapping(uint256 => string) middleNamesList;
        mapping(uint256 => string) lastNamesList;
        // Track total count of names in each list
        uint256 firstNamesCount;
        uint256 middleNamesCount;
        uint256 lastNamesCount;
    }

    function namesStorage() internal pure returns (NamesStorage storage ns) {
        bytes32 position = NAMES_STORAGE_POSITION;
        assembly {
            ns.slot := position
        }
    }

    function resetFirstNamesList() internal {
        NamesStorage storage ns = namesStorage();
        for (uint16 i = 0; i < ns.firstNamesCount; ++i) {
            delete ns.firstNamesList[i];
        }
        ns.firstNamesCount = 0;
    }

    function resetMiddleNamesList() internal {
        NamesStorage storage ns = namesStorage();
        for (uint16 i = 0; i < ns.middleNamesCount; ++i) {
            delete ns.middleNamesList[i];
        }
        ns.middleNamesCount = 0;
    }

    function resetLastNamesList() internal {
        NamesStorage storage ns = namesStorage();
        for (uint16 i = 0; i < ns.lastNamesCount; ++i) {
            delete ns.lastNamesList[i];
        }
        ns.lastNamesCount = 0;
    }

    //  New names are automatically added as valid options for the RNG
    function registerFirstNames(
        uint256[] memory _ids,
        string[] memory _names
    ) internal {
        require(
            _names.length == _ids.length,
            "NameLoader: Mismatched id and name array lengths"
        );
        NamesStorage storage ns = namesStorage();
        uint256 len = _ids.length;
        for (uint256 i = 0; i < len; ++i) {
            require(_ids[i] <= 1024, "NameLoader: ID exceeds maximum value");
            ns.firstNamesList[_ids[i]] = _names[i];
            if (_ids[i] >= ns.firstNamesCount) {
                ns.firstNamesCount = _ids[i] + 1;
            }
        }
    }

    function registerMiddleNames(
        uint256[] memory _ids,
        string[] memory _names
    ) internal {
        require(
            _names.length == _ids.length,
            "NameLoader: Mismatched id and name array lengths"
        );
        NamesStorage storage ns = namesStorage();
        uint256 len = _ids.length;
        for (uint256 i = 0; i < len; ++i) {
            require(_ids[i] <= 1024, "NameLoader: ID exceeds maximum value");
            ns.middleNamesList[_ids[i]] = _names[i];
            if (_ids[i] >= ns.middleNamesCount) {
                ns.middleNamesCount = _ids[i] + 1;
            }
        }
    }

    //  New names are automatically added as valid options for the RNG
    function registerLastNames(
        uint256[] memory _ids,
        string[] memory _names
    ) internal {
        require(
            _names.length == _ids.length,
            "NameLoader: Mismatched id and name array lengths"
        );
        NamesStorage storage ns = namesStorage();
        uint256 len = _ids.length;
        for (uint256 i = 0; i < len; ++i) {
            require(_ids[i] <= 1024, "NameLoader: ID exceeds maximum value");
            ns.lastNamesList[_ids[i]] = _names[i];
            if (_ids[i] >= ns.lastNamesCount) {
                ns.lastNamesCount = _ids[i] + 1;
            }
        }
    }

    function lookupFirstName(
        uint256 _nameId
    ) internal view returns (string memory) {
        return namesStorage().firstNamesList[_nameId];
    }

    function lookupMiddleName(
        uint256 _nameId
    ) internal view returns (string memory) {
        return namesStorage().middleNamesList[_nameId];
    }

    function lookupLastName(
        uint256 _nameId
    ) internal view returns (string memory) {
        return namesStorage().lastNamesList[_nameId];
    }

    function getFullName(
        uint256 firstNameId,
        uint256 middleNameId,
        uint256 lastNameId
    ) internal view returns (string memory) {
        NamesStorage storage ns = namesStorage();
        return
            string(
                abi.encodePacked(
                    ns.firstNamesList[firstNameId],
                    " ",
                    ns.middleNamesList[middleNameId],
                    " ",
                    ns.lastNamesList[lastNameId]
                )
            );
    }

    function getRandomFirstName(
        uint256 randomness
    ) internal view returns (uint256) {
        NamesStorage storage ns = namesStorage();
        require(ns.firstNamesCount > 0, "Names: First-name list is empty");

        uint256 nameId = randomness % ns.firstNamesCount;
        // Ensure the name exists at this index
        while (bytes(ns.firstNamesList[nameId]).length == 0) {
            nameId = (nameId + 1) % ns.firstNamesCount;
        }
        return nameId;
    }

    function getRandomMiddleName(
        uint256 randomness
    ) internal view returns (uint256) {
        NamesStorage storage ns = namesStorage();
        require(ns.middleNamesCount > 0, "Names: Middle-name list is empty");
        uint256 nameId = randomness % ns.middleNamesCount;
        // Ensure the name exists at this index
        while (bytes(ns.middleNamesList[nameId]).length == 0) {
            nameId = (nameId + 1) % ns.middleNamesCount;
        }
        return nameId;
    }

    function getRandomLastName(
        uint256 randomness
    ) internal view returns (uint256) {
        NamesStorage storage ns = namesStorage();
        require(ns.lastNamesCount > 0, "Names: Last-name list is empty");

        uint256 nameId = randomness % ns.lastNamesCount;
        // Ensure the name exists at this index
        while (bytes(ns.lastNamesList[nameId]).length == 0) {
            nameId = (nameId + 1) % ns.lastNamesCount;
        }
        return nameId;
    }
}
