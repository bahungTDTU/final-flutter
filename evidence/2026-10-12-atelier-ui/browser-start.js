async page => {
  page.atelier = {errors: [], consoleErrors: [], writes: []};
  page.on('pageerror', error => page.atelier.errors.push(String(error)));
  page.on('console', message => { if (message.type() === 'error') page.atelier.consoleErrors.push(message.text()); });
  page.on('response', response => {
    const path = new URL(response.url()).pathname;
    if (path === '/sync' || path === '/me/preferences/sync')
      page.atelier.writes.push({path, status: response.status()});
  });
  await page.mouse.move(0, 0);
  await page.screenshot({path: 'output/playwright/atelier-ui/auth-desktop-light.png'});
  await page.setViewportSize({width: 390, height: 844});
  await page.waitForTimeout(350);
  await page.screenshot({path: 'output/playwright/atelier-ui/auth-phone-light.png'});
  await page.setViewportSize({width: 1440, height: 1000});
  await page.getByRole('textbox', {name: 'Email', exact: true}).fill('ui-refresh-owner@example.test');
  await page.getByRole('textbox', {name: 'Mật khẩu', exact: true}).fill('safe-password-123');
  await page.getByRole('button', {name: 'Đăng nhập', exact: true}).click();
  await page.waitForTimeout(900);
  return {syntheticLogin: true, tokensRecorded: false};
}
