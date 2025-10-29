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


