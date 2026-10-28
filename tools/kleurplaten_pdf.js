// Zet de SVG-kleurplaten om naar één PDF om te printen (A4 liggend), plus PNG-voorbeelden.
// Gebruik: node tools/kleurplaten_pdf.js [map-voor-voorbeelden]
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

(async () => {
  const map = path.join(__dirname, '..', 'kleurplaten');
  const svgs = fs.readdirSync(map).filter(f => f.endsWith('.svg')).sort();
  const pages = svgs.map(f => `<div class="p">${fs.readFileSync(path.join(map, f), 'utf8')}</div>`).join('');
  const html = `<!doctype html><style>@page{size:297mm 210mm;margin:0}body{margin:0}.p{width:297mm;height:210mm;page-break-after:always;overflow:hidden}.p svg{display:block}</style>${pages}`;
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.setContent(html);
  await page.pdf({ path: path.join(map, 'kleurplaten.pdf'), width: '297mm', height: '210mm', printBackground: true });
  const voorbeeld = process.argv[2];
  if (voorbeeld) {
    fs.mkdirSync(voorbeeld, { recursive: true });
    await page.setViewportSize({ width: 1123, height: 794 });
    const els = await page.$$('.p');
    for (let i = 0; i < els.length; i++) await els[i].screenshot({ path: path.join(voorbeeld, svgs[i].replace('.svg', '.png')) });
  }
  await browser.close();
  console.log('PDF met', svgs.length, "pagina's");
})();
