async page => {
  // Use the observed, visible button's canvas coordinates. An empty Flutter
  // semantics overlay covers the sheet and fails Playwright's DOM hit-target check.
  const button = page.getByRole('button', {name: 'Trung tâm bảo mật', exact: true});
  const box = await button.boundingBox();
  if (!box || box.y + box.height > 1000) throw Error('Button must be visibly inside sheet');
  await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
  await page.getByText('3 phiên hoạt động', {exact: true}).waitFor({timeout: 8000});
  await page.mouse.move(0, 0);
  await page.waitForTimeout(650);
  await page.screenshot({path: 'D:/flutter cuoi ki/evidence/2026-10-11-security-center/desktop-light.png'});
}
