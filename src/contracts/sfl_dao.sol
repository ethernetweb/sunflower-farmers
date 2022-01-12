// SPDX-License-Identifier: Unlicense
// DAO
// Version: 1.0 for Sunflower Farmers / Sunflower Land
// Written by: LiveFree @ Discord, (ethernetweb @ github)
// January 11, 2022

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";



contract SunflowerFarmersDAO {
  uint public ReferendumCount;
  address public SFLContractAddress = address(0xdf9B4b57865B403e08c85568442f95c26b7896b0);

  uint public minimumTokens = 20;

  struct Custom {
    uint _Id;
    address _Data;
    uint _Val1;
    uint _Val2;
  }

  struct Voters {
    address _Voter;
    bool _Vote;
  }

  struct Referendum {
    address _Creator;
    uint _CreatedAt;
    uint _Duration;
    uint _Majority;
    bytes32 _Title;
    string _Description;
    address _requiredNFT;
    uint _YesCount;
    Custom[] _Custom;
    Voters[] _Votes;
  }
//  mapping(uint=>Referendum) public _referendums;
  Referendum[] _referendums;



  function alreadyVoted(uint _referendum, address _voter) private returns (bool) {
    for (uint i = 0; i < _referendums[_referendum]._Votes.length; i++) {
      Referendum storage _ref = _referendums[_referendum];
      if (_ref._Votes[i]._Voter == _voter) return true;
    }
    return false;
  }


  function placeVote(uint _referendum, bool _vote) public returns (bool) {
    Referendum storage _ref = _referendums[_referendum];
    require(!alreadyVoted(_referendum,msg.sender),"You've already voted on this referendum.");
    require(_referendums.length<_referendum,"That referendum doesn't exist.");
    require(isTokenHolder(msg.sender,_referendums[_referendum]._requiredNFT),"You do not hold the necessary token to create a referendum.");
    require(hasEnoughTokens(msg.sender),"You do not hold enough tokens to place a vote.");
    _ref._Votes.push(Voters({ _Voter:msg.sender, _Vote:_vote }));
    return _vote;
  }


  function createReferendum(Referendum[] memory _referendum) public returns (bool) {
    require(_referendum.length>=4,"Not enough parameters.");
    require(isTokenHolder(msg.sender,SFLContractAddress),"You do not hold the necessary token to create a referendum.");
    require(hasEnoughTokens(msg.sender),"You do not hold enough tokens to create a referendum.");
    address requiredNFT = SFLContractAddress;
    if (_referendum.length==5) requiredNFT = address(_referendum._requiredNFT);

    Custom storage _custom;
    Voters storage _votes;
    // will setting the empty struct work this way?? ^^
    if (_referendum.length==6) {
      _custom = _referendum._Custom;
      require(_custom.Id<3,"Invalid custom referendum.");
    }

    _referendums.push(Referendum({
      _Creator: msg.address,
      _CreatedAt: block.timestmap, _Duration:_referendum[0], _Majority:_referendum[1],
      _Title:_referendum[2], _Description:_referendum[3], _requiredNFT:requiredNFT, _YesCount: 0,
      _Custom:_custom, _Votes:_votes
    }));

    ReferendumCount++;
    return true;
  }


  function tallyReferendum(uint _referendum) public returns(uint,uint,uint,bool) {
    // this might be expensive on gas?
    Referendum storage _ref = _referendums[_referendum];
    require(_ref,"That referendum doesn't exist.");
    bool diff = ((block.timestamp-_ref._CreatedAt)>=_ref._Duration);
    require(diff,"That referendum has not completed yet.");
    uint VoteCount = _ref.Voters.length;
    uint YesVotes;
    for (uint i = 0; i < VoteCount; i++) {
      Voters storage sender = _ref._Votes[i];
      if (
        SFLContractAddress.balanceOf(sender._Voter)>=minimumTokens &&
        sender._Vote
      ) YesVotes++;
    }
    uint pct = (VoteCount-YesVotes)/((VoteCount+YesVotes)/2)*100;
    bool passed = false;
    if (YesVotes>=_referendums[_referendum]._Majority) passed = true;

    if (passed) {
      if (_ref._Custom._Id == 1) SFLContractAddress = address(_ref._Custom._Data._Val1);
      else if (_ref._Custom._Id == 2) minimumTokens = _ref._Custom._Data._Val1;
    }

    return (VoteCount,YesVotes,pct,passed);
  }


  function hasEnoughTokens(address _owner) private returns (bool) {
    if (SFLContractAddress.balanceOf(_owner)>minimumTokens) return true;
    else return false;
  }

  function isTokenHolder(address _owner, address _token) private returns (bool) {
    if (_token==SFLContractAddress && SFLContractAddress.balanceOf(_owner)>0) return true;
    else if (_token!=SFLContractAddress && _token.balanceOf(_owner)>0) return true;
    else return false;
  }

}
