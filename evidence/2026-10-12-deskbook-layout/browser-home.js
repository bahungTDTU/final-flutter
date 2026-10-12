async page => {
  for (const [name, width, height] of [
    ['home-desktop-light', 1440, 1000], ['home-boundary-light',1180,800], ['home-short-light',1440,600], ['home-phone-light', 390, 844],
    ['home-small-light', 320, 740], ['home-landscape-light', 844, 390], ['home-tablet-light', 768, 1024],
  ]) {
    await page.setViewportSize({width, height});
    await page.mouse.move(0, 0);
    await page.waitForTimeout(350);
    await page.screenshot({path: `output/playwright/deskbook-ui/${name}.png`});
  }
  await page.setViewportSize({width: 1440, height: 1000});
  return {viewports: 7, appErrors: page.deskbook.errors, consoleErrors: page.deskbook.consoleErrors};
}
