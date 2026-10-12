async page => {
  for (const [name, width, height] of [
    ['home-phone-light', 390, 844], ['home-small-light', 320, 740],
    ['home-landscape-light', 844, 390], ['home-tablet-light', 768, 1024],
    ['home-desktop-light', 1440, 1000],
  ]) {
    await page.setViewportSize({width, height});
    await page.waitForTimeout(350);
    await page.screenshot({path: `output/playwright/ui-system-refresh/${name}.png`});
  }
  return {viewports: 5, appErrors: page.uiRefresh.errors,
    consoleErrors: page.uiRefresh.consoleErrors};
}
