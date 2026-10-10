async page => {
 await page.setViewportSize({width:844,height:390});
 await page.waitForTimeout(400);
 await page.mouse.move(420,330);
 await page.mouse.wheel(0,700);
 await page.waitForTimeout(500);
 await page.mouse.move(5,385);
 await page.waitForTimeout(650);
 await page.screenshot({path:'D:/flutter cuoi ki/evidence/2026-10-10-planner-motion/15-planner-landscape-card-dark.png',scale:'css'});
 await page.setViewportSize({width:1440,height:1080});
 await page.waitForTimeout(400);
 await page.mouse.move(720,750); await page.mouse.wheel(0,-3000);
 return {passed:true,viewport:'844x390',wheelScrollTested:true};
}
