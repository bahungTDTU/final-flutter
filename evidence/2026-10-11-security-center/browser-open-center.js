async page => {
  await page.getByRole('button', {name: /Hồ sơ và tùy chỉnh$/}).click();
  const center = page.getByRole('button', {name: 'Trung tâm bảo mật', exact: true});
  await center.waitFor();
  await page.waitForTimeout(400);
  const box = await center.boundingBox();
  await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
  await page.getByText('3 phiên hoạt động', {exact: true}).waitFor();
  await page.mouse.move(0, 0);
  await page.waitForTimeout(650);
  await page.screenshot({path: 'D:/flutter cuoi ki/evidence/2026-10-11-security-center/desktop-light.png'});
}
