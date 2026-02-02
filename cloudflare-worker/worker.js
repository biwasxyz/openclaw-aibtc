/**
 * Cloudflare Worker for sh.biwas.xyz
 * Serves OpenClaw + aibtc setup scripts
 *
 * Routes:
 *   /         → vps-setup.sh (default)
 *   /vps      → vps-setup.sh
 *   /local    → setup.sh (for Docker Desktop users)
 */

const GITHUB_RAW = 'https://raw.githubusercontent.com/biwasxyz/openclaw-aibtc/main';

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const path = url.pathname;

    let scriptPath;

    switch (path) {
      case '/':
      case '/vps':
        scriptPath = '/vps-setup.sh';
        break;
      case '/local':
        scriptPath = '/setup.sh';
        break;
      default:
        // Allow direct file access
        scriptPath = path;
    }

    try {
      const response = await fetch(`${GITHUB_RAW}${scriptPath}`);

      if (!response.ok) {
        return new Response('Script not found', { status: 404 });
      }

      const script = await response.text();

      return new Response(script, {
        headers: {
          'content-type': 'text/plain; charset=utf-8',
          'cache-control': 'public, max-age=300', // 5 min cache
        },
      });
    } catch (error) {
      return new Response('Error fetching script', { status: 500 });
    }
  },
};
