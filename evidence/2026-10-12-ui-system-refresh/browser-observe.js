async page => {
  page.uiRefresh = {errors: [], consoleErrors: [], writes: []};
  page.on('pageerror', error => page.uiRefresh.errors.push(String(error)));
  page.on('console', message => { if (message.type() === 'error') page.uiRefresh.consoleErrors.push(message.text()); });
  page.on('response', response => {
    const path = new URL(response.url()).pathname;
    if (path === '/sync' || path === '/me/preferences/sync')
      page.uiRefresh.writes.push({path, status: response.status()});
  });
  return {recording: true, tokensRecorded: false};
}
