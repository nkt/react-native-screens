import React from 'react';
import App from '../apps';
import * as IssueTests from '../apps/src/tests/issue-tests';
import { LogBox, Platform, Settings } from 'react-native';
import { featureFlags } from 'react-native-screens';

featureFlags.experiment.synchronousScreenUpdatesEnabled = true;
featureFlags.experiment.synchronousHeaderConfigUpdatesEnabled = true;
featureFlags.experiment.synchronousHeaderSubviewUpdatesEnabled = true;
featureFlags.experiment.androidResetScreenShadowStateOnOrientationChangeEnabled =
  true;
featureFlags.stable.debugLogging = true;

// Hide all LogBox notifications (incl. the "Open debugger to view warnings"
// banner), which cover the bottom of the screen, e.g. the native tab bar, and
// break e2e taps in Debug builds. Logs still reach the debugger console;
// uncaught errors still open the full-screen LogBox.
LogBox.ignoreAllLogs();

// e2e: `device.launchApp({ launchArgs: { rnsE2EIssueTest: 'Test4989' } })`
// renders that issue test as the app root, so it mounts on the cold launch
// instead of after navigating from the examples list. iOS only: launch args
// land in NSUserDefaults, which `Settings` reads.
const e2eIssueTestName: unknown =
  Platform.OS === 'ios' ? Settings.get('rnsE2EIssueTest') : undefined;
const E2EIssueTest =
  typeof e2eIssueTestName === 'string' && e2eIssueTestName in IssueTests
    ? IssueTests[e2eIssueTestName as keyof typeof IssueTests]
    : undefined;

export default function FabricExampleApp() {
  return E2EIssueTest ? <E2EIssueTest /> : <App />;
}
