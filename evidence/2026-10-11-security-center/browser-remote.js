async page => {
  await page.getByText('Thông tin phiên chỉ hiển thị khi đã kết nối và xác thực.',{exact:true}).waitFor();
  if (await page.getByText('1 phiên hoạt động',{exact:true}).count() !== 0)
    throw Error('Session metadata still shown after remote revocation');
  if (await page.getByRole('button',{name:'Thu hồi các phiên khác',exact:true}).isEnabled())
    throw Error('Remote expired session can still manage sessions');
  await page.mouse.move(0,0);
  await page.waitForTimeout(650);
  await page.screenshot({path:'D:/flutter cuoi ki/evidence/2026-10-11-security-center/remote-session-hidden.png'});
  await page.getByRole('button',{name:'Quay lại',exact:true}).click();
  await page.getByRole('textbox',{name:'Email',exact:true}).waitFor();
  return {result:'PASS', remoteSseLogout:true, metadataHidden:true, manualLoginRequired:true,
    events:page.securityFinal};
}
