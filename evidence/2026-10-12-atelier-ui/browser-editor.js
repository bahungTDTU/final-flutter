async page => {
  const title = page.getByRole('textbox', {name: 'Tiêu đề', exact: true});
  await title.click();
  await title.press('Control+A');
  await title.pressSequentially('Thiết kế NoteTogether · UI mới');
  await page.waitForTimeout(1400);
  const expected = 'Thiết kế NoteTogether · UI mới';
  if (await title.inputValue() !== expected) throw Error('Keyboard title replacement failed');
  await page.mouse.move(0, 0);
  await page.screenshot({path: 'output/playwright/atelier-ui/editor-desktop-light.png'});
  await page.getByRole('button', {name: 'Đổi giao diện', exact: true}).click();
  await page.waitForTimeout(350);
  if (await title.inputValue() !== expected) throw Error('Theme change lost draft');
  await page.screenshot({path: 'output/playwright/atelier-ui/editor-desktop-dark.png'});
  await page.setViewportSize({width: 390, height: 844});
  await page.waitForTimeout(350);
  if (await title.inputValue() !== expected) throw Error('Resize lost draft');
  await page.screenshot({path: 'output/playwright/atelier-ui/editor-phone-dark.png'});
  await page.getByRole('button', {name: 'Công cụ ghi chú', exact: true}).click();
  await page.getByRole('menuitem', {name: 'Đổi giao diện', exact: true}).click();
  await page.waitForTimeout(350);
  await page.screenshot({path: 'output/playwright/atelier-ui/editor-phone-light.png'});
  await page.setViewportSize({width: 1440, height: 1000});
  return {exactReplacement: true, retainedDraft: true,
    autosaveHTTP200: page.atelier.writes.some(item => item.path === '/sync' && item.status === 200),
    appErrors: page.atelier.errors, consoleErrors: page.atelier.consoleErrors};
}
