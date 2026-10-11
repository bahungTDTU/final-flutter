async page => {
  page.securityEvents = { responses: [], errors: [] };
  page.on('pageerror', error => page.securityEvents.errors.push(String(error)));
  page.on('response', response => {
    if (response.url().includes('/me/sessions'))
      page.securityEvents.responses.push({path: new URL(response.url()).pathname, status: response.status()});
  });
  await page.setViewportSize({width: 1440, height: 1000});
  await page.getByRole('textbox', {name: 'Email', exact: true}).click();
  await page.keyboard.type('security-owner@example.test');
  await page.getByRole('textbox', {name: 'Mật khẩu', exact: true}).click();
  await page.keyboard.type('safe-password-123');
  await page.getByRole('button', {name: 'Đăng nhập', exact: true}).click();
  await page.getByRole('button', {name: /Hồ sơ và tùy chỉnh$/}).waitFor({timeout: 15000});
  await page.getByRole('button', {name: /Hồ sơ và tùy chỉnh$/}).click();
}
