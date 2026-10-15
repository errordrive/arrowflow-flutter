// ArrowFlow — shop (PRD §7 economy).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ads.dart';
import '../audio.dart';
import '../game/economy.dart';
import '../state/app_state.dart';
import '../theme.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final state = context.watch<AppState>();

    Widget item({
      required IconData icon,
      required Color iconColor,
      required String title,
      required String desc,
      required int price,
      required VoidCallback onBuy,
    }) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.text)),
                  const SizedBox(height: 2),
                  Text(desc,
                      style:
                          TextStyle(fontSize: 13, color: theme.muted)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (state.spendCoins(price)) {
                  Sounds.instance.play('success');
                  onBuy();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('$title purchased!'),
                        duration: const Duration(seconds: 1)),
                  );
                } else {
                  Sounds.instance.play('fail');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Not enough coins!'),
                        duration: Duration(seconds: 1)),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, size: 16),
                  Text(' $price'),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        title: const Text('Shop'),
        backgroundColor: theme.bg,
        foregroundColor: theme.text,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.monetization_on,
                    size: 18, color: Color(0xFFFFB800)),
                const SizedBox(width: 4),
                Text('${state.coins}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.text)),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          item(
            icon: Icons.lightbulb,
            iconColor: theme.gold,
            title: 'Hint',
            desc: 'Highlights a free arrow (you own ${state.hints})',
            price: Economy.priceHint,
            onBuy: () => state.addHints(1),
          ),
          item(
            icon: Icons.favorite,
            iconColor: theme.heart,
            title: 'Extra Heart',
            desc:
                'Revive when out of lives (you own ${state.extraHearts})',
            price: Economy.priceExtraHeart,
            onBuy: () => state.addExtraHearts(1),
          ),
          item(
            icon: Icons.delete_outline,
            iconColor: theme.primary,
            title: 'Eraser',
            desc:
                'Remove any single arrow (you own ${state.erasers})',
            price: Economy.priceEraser,
            onBuy: () => state.addErasers(1),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.border),
            ),
            child: Row(
              children: [
                Icon(Icons.block, color: theme.muted),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text('Remove Ads',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                ElevatedButton(
                  onPressed: state.removedAds
                      ? null
                      : () {
                          // TODO: wire react-native-iap equivalent
                          // (in_app_purchase) before release.
                          state.setRemovedAds(true);
                          Sounds.instance.play('success');
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(state.removedAds ? 'Owned' : 'Buy'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('Watch ad for 25 coins'),
            onPressed: Ads.instance.available
                ? () async {
                    final ok = await Ads.instance.showRewarded();
                    if (ok) {
                      state.addCoins(25);
                      Sounds.instance.play('success');
                    }
                  }
                : null,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}
