async page => {
  if (await page.getByRole('textbox', {name: 'Tiêu đề', exact: true}).count())
    throw Error('Protected title input retained after relock');
  if (await page.getByRole('textbox', {name: 'Nội dung', exact: true}).count())
    throw Error('Protected editor retained after relock');
  await page.setViewportSize({width: 390, height: 844});
  await page.waitForTimeout(350);
  await page.screenshot({path: 'output/playwright/ui-system-refresh/protected-gate-phone-light.png'});
  await page.getByRole('button', {name: 'Quay lại', exact: true}).click();
  await page.setViewportSize({width: 1440, height: 1000});
  await page.waitForTimeout(350);
  return {protectedFieldsRemovedOnRelock: true, appErrors: page.uiRefresh.errors,
    consoleErrors: page.uiRefresh.consoleErrors};
}
