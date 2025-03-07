// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CutDiamond} from '../../lib/laguna-diamond-foundry/src/diamond/CutDiamond.sol';
import {DN404Fragment} from './DN404Fragment.sol';
import {DN404MetadataFragment} from './DN404MetadataFragment.sol';
import {DN404AdminFragment} from './DN404AdminFragment.sol';

/// @title Cut DN404 Diamond
/// @notice This is a dummy "implementation" contract for ERC-1967 compatibility,
/// @notice this interface is used by block explorers to generate the UI interface.
/// @dev adapted from https://github.com/zdenham/diamond-etherscan?tab=readme-ov-file
contract CutDN404Diamond is CutDiamond, DN404Fragment, DN404MetadataFragment, DN404AdminFragment {}
