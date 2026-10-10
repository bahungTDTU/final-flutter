const {chromium} = require('C:/Users/LENOVO/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs = require('fs'), path = require('path'), crypto = require('crypto');
const out = __dirname, api = 'http://127.0.0.1:8022', url = 'http://127.0.0.1:7360';
const password = 'Theme-fixture-2026!', email = `theme-${crypto.randomUUID()}@example.test`;
let browser, page;
const errors=[], warnings=[], steps=[], shots=[];
async function call(method, route, body, token) {
  const r = await fetch(api+route,{method,headers:{'Content-Type':'application/json',...(token?{Authorization:'Bearer '+token}:{})},body:body?JSON.stringify(body):undefined});
  if(!r.ok) throw new Error(`${method} ${route}: HTTP ${r.status}`);
  return r.json();
}
async function shot(name) {
  await page.waitForTimeout(350);
  await page.screenshot({path:path.join(out,name+'.png')});
  shots.push(name+'.png');
}
async function tap(target) {
  await target.waitFor({state:'visible'});
  await page.waitForTimeout(180);
  if(!(await target.isEnabled())) throw new Error('Control disabled');
  const box=await target.boundingBox();
  if(!box) throw new Error('No rendered control bounds');
  // Flutter's semantics grouping nodes overlap DOM hit targets. Use a real
  // pointer at the visible control rather than force-clicking a DOM element.
  await page.mouse.click(box.x+box.width/2,box.y+box.height/2);
}
async function button(name) {
  const escaped=name.replace(/[.*+?^${}()|[\]\\]/g,'\\$&');
  const matching=name==='Hồ sơ và tùy chỉnh'? /Hồ sơ và tùy chỉnh/ : new RegExp('^'+escaped+'(?:\\s|$)');
  await tap(page.getByRole('button',{name:matching}));
}
async function close() { await button('Đóng'); await page.waitForTimeout(300); }
async function renderedText(needle) {
  await page.waitForFunction(text => [...document.querySelectorAll('flt-semantics,input,textarea')].some(el =>
    [el.textContent,el.value,el.getAttribute('aria-label')].filter(Boolean).join(' ').includes(text)), needle);
}
async function mark(name, action) {
  await action(); steps.push(name); console.log('PASS '+name);
}
(async()=>{
 const owner=await call('POST','/auth/register',{email,name:'QA theme local',password,confirmation:password});
 const peer=await call('POST','/auth/register',{email:`peer-${crypto.randomUUID()}@example.test`,name:'Người nhận QA',password,confirmation:password});
 const label=crypto.randomUUID(), noteId=crypto.randomUUID(), locked=crypto.randomUUID();
 await call('POST','/labels/sync',{op_id:crypto.randomUUID(),label_id:label,base_revision:0,kind:'upsert',name:'Thiết kế'},owner.token);
 for(const [id,title] of [[noteId,'Đồng bộ theme NoteTogether'],[locked,'PRIVATE locked theme fixture']]) {
  await call('POST','/sync',{op_id:crypto.randomUUID(),note_id:id,base_revision:0,kind:'upsert',title,content:'## Mục tiêu\nĐồng bộ theme trên tất cả màn hình.\n- [ ] Kiểm tra light và dark\n- [x] Giữ bản nháp an toàn',labels:[label],labels_format:'ids'},owner.token);
 }
 await call('POST',`/notes/${locked}/protection`,{password:'Theme-note-2026!',confirmation:'Theme-note-2026!'},owner.token);
 browser=await chromium.launch({channel:'chrome',headless:true});
 const context=await browser.newContext({viewport:{width:1440,height:960},deviceScaleFactor:1});
 page=await context.newPage(); page.setDefaultTimeout(15000);
 page.on('pageerror',e=>errors.push(String(e)));
 page.on('console',m=>{if(m.type()==='error')errors.push(m.text());if(m.type()==='warning')warnings.push(m.text());});
 await page.goto(url); await page.locator('flt-glass-pane').waitFor({state:'attached'});
 await page.waitForTimeout(1000);
 await page.evaluate(()=>document.querySelector('flt-semantics-placeholder')?.click());
 await page.getByRole('textbox',{name:'Email',exact:true}).waitFor({timeout:30000});
 await mark('auth brand panel + real login',async()=>{
  await shot('auth-desktop');
  await page.getByRole('textbox',{name:'Email',exact:true}).fill(email);
  await page.getByRole('textbox',{name:'Mật khẩu',exact:true}).fill(password);
  await button('Đăng nhập'); await page.getByText('Ghi chú của bạn',{exact:true}).waitFor();
  await page.waitForTimeout(800); await shot('home-desktop');
  if((await page.locator('body').ariaSnapshot()).includes('PRIVATE locked theme fixture'))throw new Error('Locked title leaked');
 });
 await mark('settings + avatar + disabled upload',async()=>{
  await button('Hồ sơ và tùy chỉnh'); await page.getByText('Hồ sơ và tùy chỉnh',{exact:true}).waitFor(); await shot('settings-light');
  await button('Đổi ảnh đại diện'); await page.getByText('Ảnh đại diện',{exact:true}).waitFor();
  await page.getByRole('button',{name:'Tải ảnh lên',exact:true}).isDisabled().then(v=>{if(!v)throw new Error('No image upload should be disabled');});
  await shot('avatar-light'); await close();
  await button('Đổi mật khẩu'); await page.getByRole('textbox',{name:'Mật khẩu hiện tại',exact:true}).waitFor(); await shot('password-light'); await button('Hủy');
 });
 await mark('labels + input dialog cancel',async()=>{
  await button('Quản lý nhãn'); await page.getByText(/Nhãn của tôi/).waitFor(); await shot('labels-light');
  await button('Thêm nhãn'); await page.getByRole('textbox').last().fill('Nhãn QA'); await shot('label-input-light');
  await button('Hủy'); await close();
 });
 await mark('filter sheet apply',async()=>{
  await button('Bộ lọc nhãn'); await tap(page.getByRole('checkbox',{name:'Thiết kế',exact:true})); await shot('filter-light');
  await tap(page.getByRole('button',{name:/Áp dụng/})); await button('Bỏ bộ lọc nhãn');
 });
 await mark('studio gallery + preview',async()=>{
  await button('Xưởng ghi chú'); await page.getByText('Xưởng ghi chú',{exact:true}).waitFor(); await shot('studio-light');
  await button('Xem trước mẫu'); await shot('studio-preview-light'); await button('Đóng xem trước'); await tap(page.getByRole('button',{name:/Quay lại|Back/}));
 });
 await mark('editor + real autosave + content across theme/resize',async()=>{
  await tap(page.getByRole('group',{name:/^Đồng bộ theme NoteTogether/}));
  await page.getByRole('textbox',{name:'Nội dung',exact:true}).waitFor(); await shot('editor-light');
  const field=page.getByRole('textbox',{name:'Nội dung',exact:true});
  await tap(field); await page.keyboard.press('Control+A');
  await page.keyboard.insertText('## Theme được cập nhật\nNội dung giữ nguyên khi đổi theme và resize.');
  await page.waitForTimeout(1300);
  const detail=await call('GET',`/notes/${noteId}`,undefined,owner.token);
  if(!detail.content.includes('Theme được cập nhật'))throw new Error('Autosave not acknowledged');
  await button('Đổi giao diện'); await page.setViewportSize({width:390,height:844}); await page.waitForTimeout(500);
  if(!(await page.getByRole('textbox',{name:'Nội dung',exact:true}).inputValue()).includes('Theme được cập nhật'))throw new Error('Editor content lost');
  await shot('editor-mobile-dark'); await page.setViewportSize({width:1440,height:960});
  await page.waitForTimeout(400);
  await button('Đổi giao diện');
 });
 await mark('share dialog real recipient + role control',async()=>{
  await button('Chia sẻ ghi chú'); await page.getByRole('textbox',{name:'Email người nhận',exact:true}).fill(peer.user.email);
  await button('Thêm người nhận'); await page.waitForTimeout(500);
  const recipient=page.getByRole('button',{name:/^Người nhận QA /});
  if(!(await recipient.count()) && await page.getByRole('button',{name:'Thêm người nhận',exact:true}).isEnabled()) {
    await page.getByRole('button',{name:'Thêm người nhận',exact:true}).press('Enter');
  }
  await recipient.waitFor();
  const shares=await call('GET',`/notes/${noteId}/shares`,undefined,owner.token);
  if(!shares.recipients.some(row=>row.email===peer.user.email&&row.role==='viewer'))throw new Error('Recipient was not saved');
  await shot('share-light'); await close();
 });
 await mark('attachment picker + private upload',async()=>{
  await button('Đính kèm'); const chooserPromise=page.waitForEvent('filechooser'); await button('Chọn tệp');
  await (await chooserPromise).setFiles({name:'theme-fixture.txt',mimeType:'text/plain',buffer:Buffer.from('Disposable private UI fixture')});
  await button('Tải tệp lên'); await page.getByText('Server đã lưu tệp đính kèm.',{exact:true}).waitFor(); await shot('files-light'); await close();
 });
 await mark('summary fixture + regenerate dialog',async()=>{
  await button('Tóm tắt bằng AI');
  let responsePromise=page.waitForResponse(r=>r.url().endsWith(`/notes/${noteId}/ai/summary`)&&r.request().method()==='POST');
  await tap(page.getByRole('button',{name:/Tạo tóm tắt/}));
  let result=await (await responsePromise).json();
  if(!result.summary.includes('Kết quả fixture kiểm thử, không phải LLM:'))throw new Error('Unexpected summary response');
  responsePromise=page.waitForResponse(r=>r.url().endsWith(`/notes/${noteId}/ai/summary`)&&r.request().method()==='POST');
  await button('Tạo lại');
  result=await (await responsePromise).json();
  if(!result.summary.includes('Kết quả fixture kiểm thử, không phải LLM:'))throw new Error('Unexpected regenerated summary');
  await renderedText('Bản tóm tắt'); await page.getByRole('button',{name:/^Đồng bộ theme NoteTogether/}).waitFor();
  await shot('summary-light'); await close();
 });
 await button('Quay lại'); await page.getByText('Ghi chú của bạn',{exact:true}).waitFor();
 await mark('Q&A real UI with explicit provider fixture',async()=>{
  await button('Hỏi ghi chú'); const questionField=page.getByRole('textbox',{name:'Câu hỏi của bạn',exact:true}); await tap(questionField); await page.keyboard.insertText('Theme được cập nhật thế nào?'); if(!(await questionField.inputValue()).includes('Theme'))throw new Error('Question input did not persist');
  const responsePromise=page.waitForResponse(r=>r.url().endsWith('/ai/questions')&&r.request().method()==='POST');
  await tap(page.getByRole('button',{name:/Hỏi AI/}));
  const result=await (await responsePromise).json();
  if(!result.answer.includes('Kết quả fixture kiểm thử, không phải LLM.'))throw new Error('Unexpected answer response');
  await renderedText('Câu trả lời'); await page.getByRole('button',{name:/^Đồng bộ theme NoteTogether/}).waitFor(); await shot('questions-light');
  await button('Ghi chú');
 });
 await mark('protected unlock + relock and redaction',async()=>{
  await tap(page.getByRole('button',{name:/^Ghi chú đã khóa/})); await page.getByRole('textbox',{name:'Mật khẩu ghi chú',exact:true}).fill('Theme-note-2026!');
  await shot('protected-unlock-light'); await button('Mở khóa'); await page.getByRole('button',{name:'Chỉnh sửa',exact:true}).waitFor(); await shot('protected-reader-light'); await button('Chỉnh sửa'); await page.getByRole('textbox',{name:'Nội dung',exact:true}).waitFor(); await shot('protected-editor-light');
  await button('Khóa lại'); await page.getByRole('textbox',{name:'Mật khẩu ghi chú',exact:true}).waitFor();
  if((await page.locator('body').ariaSnapshot()).includes('PRIVATE locked theme fixture'))throw new Error('Relock leaked private title');
  await button('Quay lại');
 });
 await mark('dark settings + phone/tablet/landscape navigation',async()=>{
  await button('Hồ sơ và tùy chỉnh'); await tap(page.getByRole('switch',{name:'Giao diện tối',exact:true})); await shot('settings-dark'); await button('Đóng tùy chỉnh');
  await page.setViewportSize({width:768,height:1024}); await shot('home-tablet-dark');
  await page.setViewportSize({width:390,height:844}); await shot('home-mobile-dark');
  await button('Hồ sơ và tùy chỉnh'); await shot('settings-mobile-dark'); await button('Đóng tùy chỉnh');
  await page.setViewportSize({width:844,height:390}); await shot('home-landscape-dark');
  await page.setViewportSize({width:1440,height:960});
 });
 const result={date_utc:new Date().toISOString(),url:page.url(),title:await page.title(),browser:await browser.version(),fixture:{email,note_id:noteId,locked_id:locked},viewports:['1440x960','390x844','768x1024','844x390'],browser_plugin:'Absent; regular bundled Playwright',steps,shots,errors,warnings,ai:'Explicit fixture-not-an-llm; no Gemini call',physical_native:'NOT RUN',release:'NOT RUN'};
 fs.writeFileSync(path.join(out,'qa.json'),JSON.stringify(result,null,2));
 if(errors.length)throw new Error('App console errors');
 console.log(JSON.stringify(result)); await browser.close();
})().catch(async e=>{
 console.error(String(e));
 if(page){await page.screenshot({path:path.join(out,'failure.png')}).catch(()=>{});fs.writeFileSync(path.join(out,'failure-dom.txt'),await page.locator('body').ariaSnapshot().catch(()=>''));}
 fs.writeFileSync(path.join(out,'partial.json'),JSON.stringify({steps,shots,errors,warnings,error:String(e)},null,2));
 if(browser)await browser.close();process.exitCode=1;
});
