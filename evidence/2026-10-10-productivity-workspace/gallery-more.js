async page => {
  await page.keyboard.press('Escape');
  await page.setViewportSize({width:1440,height:960});
  await page.getByRole('checkbox', {name:'Yêu thích',exact:true}).click();
  await page.getByRole('button', {name:'Kế hoạch sáng tạo Ghi chú của bạn',exact:true}).click();
  await page.getByRole('button', {name:'Đổi giao diện',exact:true}).click();
  await page.getByRole('button', {name:'Quay lại',exact:true}).click();
  await page.getByRole('checkbox', {name:'Tổng quan',exact:true}).click();
  await page.setViewportSize({width:390,height:844});
  await page.waitForTimeout(700);
  await page.screenshot({path:'output/playwright/workspace-2026-10-10/18-overview-mobile-light.png'});
  await page.setViewportSize({width:844,height:390});
  await page.waitForTimeout(700);
  await page.screenshot({path:'output/playwright/workspace-2026-10-10/19-overview-landscape.png'});
  await page.setViewportSize({width:768,height:1024});
  await page.waitForTimeout(700);
  await page.screenshot({path:'output/playwright/workspace-2026-10-10/20-overview-tablet.png'});
  await page.setViewportSize({width:1440,height:960});
  await page.getByRole('checkbox', {name:'Bộ sưu tập',exact:true}).click();
  await page.getByRole('checkbox', {name:'Kế hoạch đang làm',exact:true}).click();
  await page.waitForTimeout(700);
  await page.screenshot({path:'output/playwright/workspace-2026-10-10/21-collection-final.png'});
  await page.getByRole('checkbox', {name:'Mẫu riêng',exact:true}).click();
  await page.waitForTimeout(700);
  await page.screenshot({path:'output/playwright/workspace-2026-10-10/22-templates-final.png'});
}
