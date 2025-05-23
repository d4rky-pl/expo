import { BuildCacheProvider, getConfig } from '@expo/config';

import { resolveDeviceAsync } from './resolveDevice';
import { GradleProps, resolveGradlePropsAsync } from './resolveGradlePropsAsync';
import { LaunchProps, resolveLaunchPropsAsync } from './resolveLaunchProps';
import { AndroidDeviceManager } from '../../start/platforms/android/AndroidDeviceManager';
import { resolveBuildCacheProvider } from '../../utils/build-cache-providers';
import { BundlerProps, resolveBundlerPropsAsync } from '../resolveBundlerProps';

export type Options = {
  variant?: string;
  device?: boolean | string;
  port?: number;
  bundler?: boolean;
  install?: boolean;
  buildCache?: boolean;
  allArch?: boolean;
  binary?: string;
  appId?: string;
};

export type ResolvedOptions = GradleProps &
  BundlerProps &
  LaunchProps & {
    variant: string;
    buildCache: boolean;
    device: AndroidDeviceManager;
    install: boolean;
    architectures?: string;
    appId?: string;
    buildCacheProvider?: BuildCacheProvider;
  };

export async function resolveOptionsAsync(
  projectRoot: string,
  options: Options
): Promise<ResolvedOptions> {
  // Resolve the device before the gradle props because we need the device to be running to get the ABI.
  const device = await resolveDeviceAsync(options.device);

  const projectConfig = getConfig(projectRoot);
  const buildCacheProvider = await resolveBuildCacheProvider(
    projectConfig.exp.experiments?.buildCacheProvider ??
      projectConfig.exp.experiments?.remoteBuildCache?.provider,
    projectRoot
  );

  return {
    ...(await resolveBundlerPropsAsync(projectRoot, options)),
    ...(await resolveGradlePropsAsync(projectRoot, options, device.device)),
    ...(await resolveLaunchPropsAsync(projectRoot, options)),
    variant: options.variant ?? 'debug',
    // Resolve the device based on the provided device id or prompt
    // from a list of devices (connected or simulated) that are filtered by the scheme.
    device,
    buildCache: !!options.buildCache,
    install: !!options.install,
    buildCacheProvider,
  };
}
