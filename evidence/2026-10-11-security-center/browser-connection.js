async page => {
  await page.context().setOffline(true);
  await page.getByRole('button', {name: 'Tải lại phiên', exact: true}).click();
  await page.getByText('Thông tin phiên chỉ hiển thị khi đã kết nối và xác thực.', {exact: true}).waitFor();
  if (await page.getByRole('button', {name: 'Thu hồi các phiên khác', exact: true}).isEnabled())
    throw Error('Offline stale actions must be disabled');
  await page.mouse.move(0, 0);
  await page.waitForTimeout(650);
  await page.screenshot({path: 'D:/flutter cuoi ki/evidence/2026-10-11-security-center/offline-hidden.png'});
  await page.context().setOffline(false);
  await page.getByRole('button', {name: 'Tải lại phiên', exact: true}).click();
  await page.getByText('1 phiên hoạt động', {exact: true}).waitFor();
  return {result:'PASS', offlineHidesRows:true, onlineReload:true, events:page.securityEvents};
}
