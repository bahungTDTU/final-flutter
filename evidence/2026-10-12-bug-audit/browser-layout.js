async page => {
  await page.setViewportSize({ width: 1000, height: 850 });
  await page.waitForTimeout(150);
  const problems = [];
  const onError = error => problems.push(String(error));
  const onConsole = message => { if (message.type() === 'error') problems.push(message.text()); };
  page.on('pageerror', onError);
  page.on('console', onConsole);
  const title = page.getByRole('textbox', { name: 'Tiêu đề', exact: true });
  const before = await title.inputValue();
  if (await page.getByRole('heading', { name: 'Mục lục', exact: true }).count() === 0) {
    await page.getByRole('button', { name: 'Hiện/ẩn mục lục', exact: true }).click();
  }
  await page.getByRole('heading', { name: 'Mục lục', exact: true }).waitFor();
  const zoomLabel = await page.getByRole('group', { name: /^Trang viết / }).getAttribute('aria-label');
  const initialZoom = Number(zoomLabel.match(/(\d+)%/)[1]);
  for (let index = initialZoom; index < 140; index += 10) {
    await page.getByRole('button', { name: /^Phóng to tài liệu/ }).click();
    await page.mouse.move(0, 0);
    await page.waitForTimeout(150);
  }
  await page.screenshot({ path: 'D:/flutter cuoi ki/output/playwright/bug-audit-desktop-light.png' });
  await page.getByRole('button', { name: /^Đổi giao diện/ }).click();
  await page.mouse.move(0, 0);
  await page.waitForTimeout(250);
  await page.screenshot({ path: 'D:/flutter cuoi ki/output/playwright/bug-audit-desktop-dark.png' });
  await page.setViewportSize({ width: 390, height: 844 });
  await page.waitForTimeout(250);
  await page.screenshot({ path: 'D:/flutter cuoi ki/output/playwright/bug-audit-phone-dark.png' });
  await page.getByRole('button', { name: 'Công cụ ghi chú', exact: true }).click();
  await page.getByRole('menuitem', { name: 'Đổi giao diện', exact: true }).click();
  await page.mouse.move(0, 0);
  await page.waitForTimeout(250);
  await page.screenshot({ path: 'D:/flutter cuoi ki/output/playwright/bug-audit-phone-light.png' });
  await page.setViewportSize({ width: 1000, height: 850 });
  await page.waitForTimeout(250);
  if (await title.inputValue() !== before) throw new Error('Resize/theme changed the note title');
  if (problems.length) throw new Error(JSON.stringify(problems));
  page.removeListener('pageerror', onError);
  page.removeListener('console', onConsole);
  return { result: 'PASS', desktop: '1000x850 / both drawers / zoom140%', phone: '390x844', themes: ['light', 'dark'], titlePreserved: true, pageConsoleErrors: problems.length };
}
