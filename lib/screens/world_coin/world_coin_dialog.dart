import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/localization/world_coin_strings.dart';
import '../../models/economy.dart';
import '../../services/world_coin_service.dart';
import '../../widgets/world_coin/world_coin_icon.dart';

Future<void> showWorldCoins(BuildContext context) {
  AppScope.of(context, listen: false).online?.event('world_coin_modal_opened');
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .78),
    builder: (_) => const WorldCoinDialog(),
  );
}

class WorldCoinBalanceChip extends StatelessWidget {
  const WorldCoinBalanceChip({super.key});

  @override
  Widget build(BuildContext context) {
    final balance = AppScope.of(context).online?.worldCoinBalance ?? 0;
    final copy = WorldCoinStrings.of(context);
    return Semantics(
      button: true,
      label: '${copy['title']}: $balance',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('world_coin_balance_button'),
          onTap: () => showWorldCoins(context),
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(5, 4, 9, 4),
            decoration: BoxDecoration(
              color: const Color(0xCC182126),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x99FFD45C)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const WorldCoinIcon(size: 30),
                const SizedBox(width: 5),
                Text(
                  '$balance',
                  key: const Key('world_coin_header_balance'),
                  style: const TextStyle(
                    color: Color(0xFFFFF4DE),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _DialogState { loading, ready, processing, unavailable }

class WorldCoinDialog extends StatefulWidget {
  const WorldCoinDialog({super.key});

  @override
  State<WorldCoinDialog> createState() => _WorldCoinDialogState();
}

class _WorldCoinDialogState extends State<WorldCoinDialog> {
  _DialogState _state = _DialogState.loading;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    final controller = AppScope.of(context, listen: false);
    try {
      await controller.refreshOnline();
      final ready = await controller.worldCoins!.prepareRewardedAd();
      if (mounted) {
        setState(
          () => _state = ready ? _DialogState.ready : _DialogState.unavailable,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _state = _DialogState.unavailable);
    }
  }

  Future<void> _watch() async {
    final copy = WorldCoinStrings.of(context);
    final controller = AppScope.of(context, listen: false);
    if (controller.online?.connected != true) {
      setState(() => _message = copy['offline']);
      return;
    }
    setState(() {
      _state = _DialogState.processing;
      _message = null;
    });
    try {
      if (!controller.ads.isRewardedReady) {
        setState(() => _state = _DialogState.loading);
      }
      if (!controller.ads.isRewardedReady &&
          !await controller.worldCoins!.prepareRewardedAd()) {
        if (mounted) {
          setState(() {
            _state = _DialogState.unavailable;
            _message = copy['unavailable'];
          });
        }
        return;
      }
      if (mounted) setState(() => _state = _DialogState.processing);
      final result = await controller.earnWorldCoin();
      if (!mounted) return;
      setState(() {
        _state = _DialogState.ready;
        _message = switch (result.status) {
          WorldCoinEarnStatus.granted => '+${result.amount} World Coin',
          WorldCoinEarnStatus.rewardNotEarned => copy['notEarned'],
          WorldCoinEarnStatus.confirmationPending => copy['pending'],
          WorldCoinEarnStatus.adUnavailable => copy['unavailable'],
        };
      });
    } on WorldCoinOfflineException {
      if (mounted) setState(() => _message = copy['offline']);
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      if (error.code == 'resource-exhausted') {
        await controller.refreshOnline();
      }
      setState(() {
        _message = error.code == 'resource-exhausted'
            ? copy['limit']
            : error.code == 'unauthenticated'
            ? copy['offline']
            : copy['unavailable'];
      });
    } catch (_) {
      if (mounted) setState(() => _message = copy['unavailable']);
    } finally {
      if (mounted) setState(() => _state = _DialogState.ready);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final service = controller.worldCoins!;
    final copy = WorldCoinStrings.of(context);
    final atLimit = service.dailyLimitReached;
    final loading = _state == _DialogState.loading;
    final processing = _state == _DialogState.processing;
    final enabled = !atLimit && !loading && !processing;
    final buttonText = atLimit
        ? copy['limit']
        : processing
        ? copy['processing']
        : loading
        ? copy['loading']
        : '${copy['watch']}  •  +${service.rewardAmount} World Coin';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        key: const Key('world_coin_dialog'),
        constraints: const BoxConstraints(maxWidth: 390),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF60451D), Color(0xFF2A2117), Color(0xFF151A1D)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFD45C), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const WorldCoinIcon(size: 54),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    copy['title'],
                    style: const TextStyle(
                      color: Color(0xFFFFF4DE),
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: copy['close'],
                  onPressed: processing ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              copy['balance'],
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              '${service.balance}',
              key: const Key('world_coin_modal_balance'),
              style: const TextStyle(
                color: Color(0xFFFFD45C),
                fontSize: 42,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              copy['explanation'],
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 16),
            Semantics(
              label: '${copy['watch']}, +${service.rewardAmount} World Coin',
              button: true,
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton.icon(
                  key: const Key('world_coin_watch_ad_button'),
                  onPressed: enabled ? _watch : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC52D),
                    foregroundColor: const Color(0xFF281900),
                    disabledBackgroundColor: const Color(0xFF806B3C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: processing || loading
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.play_circle_fill_rounded),
                  label: Text(
                    buttonText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '${copy['today']}: ${service.earnedToday} / ${service.dailyLimit}',
              key: const Key('world_coin_daily_progress'),
              style: const TextStyle(
                color: Color(0xFFFFE7A3),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (atLimit) ...[
              const SizedBox(height: 6),
              Text(copy['tomorrow'], textAlign: TextAlign.center),
            ],
            if (_message != null) ...[
              const SizedBox(height: 10),
              Text(
                _message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _message!.startsWith('+')
                      ? const Color(0xFF8FF0A4)
                      : Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              copy['future'],
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
