async page => {
  await page.getByRole('button', {name: 'Đổi giao diện', exact: true}).click();
  await page.getByRole('button', {name: 'Quay lại', exact: true}).click();
  for (const [name,width,height] of [
    ['home-desktop-dark',1440,1000], ['home-boundary-dark',1180,800], ['home-short-dark',1440,600], ['home-phone-dark',390,844],
    ['home-small-dark',320,740], ['home-landscape-dark',844,390], ['home-tablet-dark',768,1024],
  ]) {
    await page.setViewportSize({width,height});
    await page.mouse.move(0,0);
    await page.waitForTimeout(350);
    await page.screenshot({path:`output/playwright/deskbook-ui/${name}.png`});
  }
  await page.setViewportSize({width:1440,height:1000});
  return {darkViewports:7, appErrors:page.deskbook.errors, consoleErrors:page.deskbook.consoleErrors};
}
