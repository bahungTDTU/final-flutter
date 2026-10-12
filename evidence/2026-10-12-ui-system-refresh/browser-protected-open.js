async page => {
  await page.mouse.move(950, 820);
  await page.mouse.wheel(0, 700);
  await page.waitForTimeout(350);
  if (await page.getByText('Bản ghi riêng tư', {exact: true}).count())
    throw Error('Protected title appears before unlock');
  await page.getByRole('button', {name: 'Ghi chú đã khóa Mở khóa để xem nội dung. Đã khóa', exact: true}).click();
  await page.waitForTimeout(350);
  await page.screenshot({path: 'output/playwright/ui-system-refresh/protected-gate-desktop-light.png'});
  return {protectedTitleHiddenBeforeUnlock: true, appErrors: page.uiRefresh.errors};
}
