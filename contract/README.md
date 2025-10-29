# 📝 NoteFi — Minimal Decentralised Writing DApp

> A lightweight and beginner-friendly **Web3 DApp** for creating, updating, deleting, and tipping notes — all stored on the **Ethereum blockchain**.

---

<img width="1920" height="1020" alt="image" src="https://github.com/user-attachments/assets/9d72e421-7b84-4af5-a53e-d55e4901891c" />


## 🚀 Project Description

**NoteFi** is a simple yet powerful **decentralised writing platform** built using **Solidity**.  
It allows users to publish short text-based notes directly on the blockchain — without any central authority or censorship.  
Each note belongs to its author, can receive **ETH tips** from other users, and is stored immutably once created.

This project is great for **Web3 beginners** to learn about:
- Structs and mappings  
- Events and modifiers  
- Ether transfers  
- Smart contract architecture  

---

## 💡 What It Does

- ✅ Lets users **create** new notes (stored on-chain)
- ✏️ Allows authors to **update** or **delete** their own notes
- 💰 Enables users to **tip** note authors in Ether
- 🔍 Fetches individual notes or all note IDs owned by a user
- ⏱️ Tracks creation and update timestamps for transparency
- 📜 Emits events for every key action (create, update, delete, tip)

---

## ✨ Features

| Feature | Description |
|----------|-------------|
| 🧠 **Create Notes** | Write and publish your note on the blockchain. |
| 🛠️ **Edit Notes** | Update your note anytime — only the author can edit. |
| 🗑️ **Delete Notes** | Soft-delete functionality keeps record but marks as deleted. |
| 💸 **Tip Authors** | Support your favorite note writers with ETH tips. |
| ⏰ **Timestamps** | Records creation and update times for each note. |
| 🔒 **Ownership Restriction** | Only the author can modify or delete their own notes. |

---

## 🔗 Deployed Smart Contract

**Contract Address:** `https://celo-sepolia.blockscout.com/address/0x09d0bC5B29A2e93e5FE3d80046c4C2B209f7Fbb5`  
**Network:** Ethereum / Testnet (e.g. Sepolia, Goerli, etc.)

---

## 🧩 Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title NoteFi - Minimal Decentralised Writing DApp
/// @notice Create, update, delete and tip simple text notes
contract NoteFi {
    struct Note {
        uint256 id;
        address author;
        string content;
        uint256 createdAt;
        uint256 updatedAt;
        uint256 totalTipsWei;
        bool deleted;
    }

    // next note id (starts at 1 so 0 can be treated as "not found")
    uint256 public nextNoteId = 1;

    // noteId => Note
    mapping(uint256 => Note) private notes;

    // author => list of their noteIds (includes deleted for historical reference)
    mapping(address => uint256[]) private authorToNoteIds;

    event NoteCreated(uint256 indexed id, address indexed author, string content);
    event NoteUpdated(uint256 indexed id, string newContent);
    event NoteDeleted(uint256 indexed id);
    event NoteTipped(uint256 indexed id, address indexed from, uint256 amountWei);

    modifier onlyAuthor(uint256 noteId) {
        require(notes[noteId].author == msg.sender, "Not author");
        _;
    }

    function createNote(string calldata content) external returns (uint256 noteId) {
        require(bytes(content).length > 0, "Empty content");

        noteId = nextNoteId++;
        Note storage n = notes[noteId];
        n.id = noteId;
        n.author = msg.sender;
        n.content = content;
        n.createdAt = block.timestamp;
        n.updatedAt = block.timestamp;

        authorToNoteIds[msg.sender].push(noteId);
        emit NoteCreated(noteId, msg.sender, content);
    }

    function updateNote(uint256 noteId, string calldata newContent) external onlyAuthor(noteId) {
        Note storage n = notes[noteId];
        require(!n.deleted, "Note deleted");
        require(n.id != 0, "Note not found");
        require(bytes(newContent).length > 0, "Empty content");

        n.content = newContent;
        n.updatedAt = block.timestamp;
        emit NoteUpdated(noteId, newContent);
    }

    function deleteNote(uint256 noteId) external onlyAuthor(noteId) {
        Note storage n = notes[noteId];
        require(n.id != 0, "Note not found");
        require(!n.deleted, "Already deleted");
        n.deleted = true;
        n.updatedAt = block.timestamp;
        emit NoteDeleted(noteId);
    }

    /// @notice Tip a note author. Ether is forwarded to the author.
    function tipNote(uint256 noteId) external payable {
        Note storage n = notes[noteId];
        require(n.id != 0, "Note not found");
        require(!n.deleted, "Note deleted");
        require(msg.value > 0, "Zero tip");

        n.totalTipsWei += msg.value;

        // forward funds to author
        (bool ok, ) = n.author.call{value: msg.value}("");
        require(ok, "Tip transfer failed");

        emit NoteTipped(noteId, msg.sender, msg.value);
    }

    function getNote(uint256 noteId)
        external
        view
        returns (
            uint256 id,
            address author,
            string memory content,
            uint256 createdAt,
            uint256 updatedAt,
            uint256 totalTipsWei,
            bool deleted
        )
    {
        Note storage n = notes[noteId];
        require(n.id != 0, "Note not found");
        return (n.id, n.author, n.content, n.createdAt, n.updatedAt, n.totalTipsWei, n.deleted);
    }

    function getMyNoteIds() external view returns (uint256[] memory) {
        return authorToNoteIds[msg.sender];
    }
}



