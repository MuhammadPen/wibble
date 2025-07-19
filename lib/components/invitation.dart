import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wibble/firebase/firebase_utils.dart';
import 'package:wibble/firebase/firestore/index.dart';
import 'package:wibble/main.dart';
import 'package:wibble/types.dart';
import 'package:wibble/utils/lobby.dart';

class InvitationWidget extends StatefulWidget {
  const InvitationWidget({Key? key}) : super(key: key);

  @override
  State<InvitationWidget> createState() => _InvitationWidgetState();
}

class _InvitationWidgetState extends State<InvitationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleAccept(Invite invite) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final store = context.read<Store>();

      // Check if user is already in a lobby
      final isInLobby =
          store.lobbyData.id.isNotEmpty && store.lobbyData.players.isNotEmpty;

      if (isInLobby) {
        // Show confirmation dialog
        final shouldAccept = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave Current Game?'),
            content: const Text(
              'You are currently in a lobby. Accepting this invite will cancel your current game. Are you sure?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Accept Invite'),
              ),
            ],
          ),
        );

        if (shouldAccept != true) {
          setState(() {
            _isProcessing = false;
          });
          return;
        }
      }

      // Cancel all existing lobby subscriptions and clear store lobby data
      if (isInLobby) {
        // Leave the current lobby if user was in one
        await leaveLobby(lobbyId: store.lobbyData.id, playerId: store.user.id);
      }
      store.cancelLobbySubscription();
      store.lobbyData = getEmptyLobby();

      // Get the lobby data for the invite
      final lobbyDoc = await Firestore().getDocument(
        collectionId: FirestoreCollections.multiplayer.name,
        documentId: invite.lobbyId,
      );

      if (lobbyDoc.exists && lobbyDoc.data() != null) {
        final lobby = Lobby.fromJson(lobbyDoc.data() as Map<String, dynamic>);

        // Check if lobby is present and has players
        if (lobby.playerCount <= 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This lobby is no longer active'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }

        // Create player info for current user
        final playerInfo = LobbyPlayerInfo(
          user: store.user,
          score: 0,
          round: 0,
          attempts: 0,
          isAdmin: false,
        );

        // Accept the invite
        await acceptInvite(
          invite: invite,
          lobby: lobby,
          playerInfo: playerInfo,
        );

        // Update store's lobby data
        final updatedLobby = Lobby(
          id: lobby.id,
          rounds: lobby.rounds,
          wordLength: lobby.wordLength,
          maxAttempts: lobby.maxAttempts,
          playerCount: lobby.playerCount + 1,
          maxPlayers: lobby.maxPlayers,
          type: lobby.type,
          startTime: lobby.startTime,
          players: {...lobby.players, store.user.id: playerInfo},
        );
        store.lobbyData = updatedLobby;

        // Start lobby subscription to stay connected
        final lobbyStream = await Firestore().subscribeToDocument(
          collectionId: FirestoreCollections.multiplayer.name,
          documentId: invite.lobbyId,
        );

        store.lobbySubscription = lobbyStream.listen((event) {
          final data = event.data();
          if (data != null) {
            store.lobbyData = Lobby.fromJson(data as Map<String, dynamic>);
          }
        });

        // Remove from local invites list
        store.invites.removeWhere((inv) => inv.id == invite.id);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Joined ${invite.sender.username}\'s lobby!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Navigate to private lobby page
          Navigator.pushNamed(context, '/privateLobby');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This lobby no longer exists'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error accepting invite: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to accept invite'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleReject(Invite invite) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await rejectInvite(invite: invite);

      // Remove from local invites list
      final store = context.read<Store>();
      store.invites.removeWhere((inv) => inv.id == invite.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Declined invite from ${invite.sender.username}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error rejecting invite: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reject invite'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Store>(
      builder: (context, store, child) {
        final invites = store.invites;

        print("💌 invites in invitation widget: ${invites}");

        if (invites.isEmpty) {
          return const SizedBox.shrink();
        }

        // Show the first invite in the queue
        final currentInvite = invites.first;

        // Trigger animation when widget appears
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_animationController.status == AnimationStatus.dismissed) {
            _animationController.forward();
          }
        });

        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with invite counter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Game Invitation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (invites.length > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${invites.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Sender info
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.blue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentInvite.sender.username,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'invited you to join their lobby',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isProcessing
                                ? null
                                : () => _handleReject(currentInvite),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              foregroundColor: Colors.grey[700],
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: _isProcessing
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Decline',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isProcessing
                                ? null
                                : () => _handleAccept(currentInvite),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isProcessing
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Accept',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),

                    // Queue indicator for multiple invites
                    if (invites.length > 1) ...[
                      const SizedBox(height: 12),
                      Text(
                        '${invites.length - 1} more invite${invites.length - 1 == 1 ? '' : 's'} pending',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
