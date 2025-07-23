import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wibble/firebase/firebase_utils.dart';
import 'package:wibble/firebase/firestore/index.dart';
import 'package:wibble/main.dart';
import 'package:wibble/types.dart';
import 'package:wibble/utils/lobby.dart';
import 'package:wibble/components/ui/button.dart';
import 'package:wibble/components/ui/shadow_container.dart';
import 'package:wibble/styles/text.dart';

class InvitationWidget extends StatefulWidget {
  const InvitationWidget({super.key});

  @override
  State<InvitationWidget> createState() => _InvitationWidgetState();
}

class _InvitationWidgetState extends State<InvitationWidget>
    with SingleTickerProviderStateMixin {
  late Store _store;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _store = context.read<Store>();
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
      // Check if user is already in a lobby
      final isInLobby =
          _store.lobby.id.isNotEmpty && _store.lobby.players.isNotEmpty;

      if (isInLobby) {
        // Show confirmation dialog
        final shouldAccept = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.transparent,
            content: ShadowContainer(
              backgroundColor: Color(0xffF2EEDB),
              child: Column(
                children: [
                  Text("Leave Current Game?", style: textStyle),
                  Text(
                    "You are currently in a lobby. Accepting this invite will cancel your current game. Are you sure?",
                    style: textStyle.copyWith(fontSize: 16),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 10,
                    children: [
                      CustomButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        text: "Accept Invite",
                        fontSize: 24,
                        horizontalPadding: 10,
                        backgroundColor: Color(0xff10A958),
                      ),
                      CustomButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        text: "Cancel",
                        fontSize: 24,
                        horizontalPadding: 10,
                        backgroundColor: Color(0xffFF2727),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
        await leaveLobby(lobbyId: _store.lobby.id, playerId: _store.user.id);
      }
      _store.cancelLobbySubscription();
      _store.lobby = getEmptyLobby();

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
          user: _store.user,
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
          players: {...lobby.players, _store.user.id: playerInfo},
        );
        _store.lobby = updatedLobby;

        // Start lobby subscription to stay connected
        final lobbyStream = await Firestore().subscribeToDocument(
          collectionId: FirestoreCollections.multiplayer.name,
          documentId: invite.lobbyId,
        );

        _store.lobbySubscription = lobbyStream.listen((event) {
          final data = event.data();
          if (data != null) {
            _store.lobby = Lobby.fromJson(data as Map<String, dynamic>);
          }
        });

        // Remove from local invites list
        _store.invites.removeWhere((inv) => inv.id == invite.id);

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
          Navigator.pushReplacementNamed(
            context,
            '/${Routes.privateLobby.name}',
          );
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
      _store.invites.removeWhere((inv) => inv.id == invite.id);

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
      builder: (context, _store, child) {
        final invites = _store.invites;

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
              child: ShadowContainer(
                backgroundColor: const Color(0xFF2D2D2D),
                shadowColor: Colors.black,
                outlineColor: Colors.black,
                padding: 10,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Queue indicator for multiple invites
                    if (invites.length > 1) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${invites.length - 1} more invite${invites.length - 1 == 1 ? '' : 's'} pending',
                          style: textStyle.copyWith(
                            fontSize: 16,
                            color: Colors.white70,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                    // Title text
                    Text(
                      'Lobby Invite from',
                      style: textStyle.copyWith(
                        color: Colors.white,
                        fontSize: 38,
                        decoration: TextDecoration.none,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Sender username
                    Text(
                      currentInvite.sender.username,
                      style: textStyle.copyWith(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            onPressed: _isProcessing
                                ? null
                                : () => _handleAccept(currentInvite),
                            text: 'Accept',
                            backgroundColor: Color(0xFF10A958),
                            fontColor: Colors.white,
                            fontSize: 38,
                            shadowColor: Color.fromARGB(100, 76, 175, 79),
                            borderColor: Color(0xFF10A958),
                            borderRadius: 16,
                            disabled: _isProcessing,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: CustomButton(
                            onPressed: _isProcessing
                                ? null
                                : () => _handleReject(currentInvite),
                            text: 'Decline',
                            backgroundColor: Color(0xFFFF2727),
                            shadowColor: Color.fromARGB(100, 255, 39, 39),
                            borderColor: Color(0xFFFF2727),
                            borderRadius: 16,
                            fontColor: Colors.white,
                            fontSize: 38,
                            disabled: _isProcessing,
                          ),
                        ),
                      ],
                    ),
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
