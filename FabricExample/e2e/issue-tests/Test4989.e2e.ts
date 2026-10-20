import { execFileSync } from 'node:child_process';
import { by, device, element, expect, waitFor } from 'detox';
import { describeIfIPhoneDuo } from '@e2e/framework/platform';
import { waitUntil } from '@e2e/framework/wait';

// https://github.com/skarol/duoctl drives the simulator's hinge. Pass its path
// in RNS_DUOCTL when it is not on PATH.
const DUOCTL = process.env.RNS_DUOCTL ?? 'duoctl';
const UNFOLD_TIMEOUT_MS = 10000;
const TAB_BAR_TIMEOUT_MS = 10000;
// Without the fix, a launch by hand always comes up without the rail, but one
// driven by Detox only about half of the time, so the test launches repeatedly.
const COLD_LAUNCHES = 3;

function duoctl(...args: string[]) {
  return execFileSync(DUOCTL, ['--device', device.id, ...args], {
    encoding: 'utf8',
  });
}

async function unfold() {
  duoctl('open');
  await waitUntil(
    async () => JSON.parse(duoctl('state')).activeScreen === 'inner',
    {
      timeout: UNFOLD_TIMEOUT_MS,
      interval: 250,
      message: 'the iPhone Duo inner display to become active',
    },
  );
}

// The bug needs TabsHost mounted on a cold launch while unfolded. Opening
// Test4989 from the issue tests list mounts it after launch and shows the rail
// even without the fix, so the launch argument renders the test as the app root.
async function coldLaunchTest4989() {
  await device.launchApp({
    newInstance: true,
    launchArgs: { rnsE2EIssueTest: 'Test4989' },
  });
}

async function expectSideRailTabBar() {
  await waitFor(element(by.id('tab-bar-item-second')))
    .toBeVisible()
    .withTimeout(TAB_BAR_TIMEOUT_MS);
  await expect(element(by.id('tab-bar-item-third'))).toBeVisible();
  // The selection lens covers the selected item, so it fails Detox's
  // visibility threshold even when shown.
  await expect(element(by.id('tab-bar-item-first'))).toExist();
  await expect(element(by.id('route-key-label'))).toHaveText('First');
}

// Run with RNS_APPLE_SIM_NAME="iPhone Duo".
describeIfIPhoneDuo('@duo Test4989', () => {
  beforeAll(async () => {
    await unfold();
  });

  it('shows the side rail tab bar after a cold launch on the unfolded device', async () => {
    for (let launch = 1; launch <= COLD_LAUNCHES; launch++) {
      await coldLaunchTest4989();
      try {
        await expectSideRailTabBar();
      } catch (error) {
        throw new Error(
          `Cold launch ${launch}/${COLD_LAUNCHES}: ${(error as Error).message}`,
        );
      }
    }
  });

  it('switches tabs from the side rail', async () => {
    await element(by.id('tab-bar-item-third')).tap();
    await expect(element(by.id('route-key-label'))).toHaveText('Third');
  });
});
