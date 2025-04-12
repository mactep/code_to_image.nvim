process.env.PUPPETEER_SKIP_DOWNLOAD = 'true';
console.log("BROWSER == " + process.env.BROWSER);

const puppeteer = require('puppeteer');

async function screenshotContainer(url, outputPath) {
	let browser;
	const selector = ".container";

	try {
		let puppeteerBrowser = process.env.BROWSER?.includes("chrom") ? "chrome" : "firefox";

		let puppeteerOptions = {
			headless: true,
			browser: puppeteerBrowser,
			executablePath: process.env.BROWSER,
		};

		console.log(`Puppeteer options: ${JSON.stringify(puppeteerOptions)}`);

		browser = await puppeteer.launch(puppeteerOptions);
		const page = await browser.newPage();
		await page.goto(url);

		// Wait for the element to be present on the page
		await page.waitForSelector(selector);

		// Get the bounding box of the element
		const element = await page.$(selector);
		if (!element) {
			console.error(`Element with selector "${selector}" not found on the page.`);
			return;
		}
		const boundingBox = await element.boundingBox();

		if (!boundingBox) {
			console.error(`Could not get bounding box for element with selector "${selector}".`);
			return;
		}

		// Take the screenshot of the element's bounding box
		await page.screenshot({
			path: outputPath,
			clip: {
				x: boundingBox.x,
				y: boundingBox.y,
				width: boundingBox.width,
				height: boundingBox.height,
			},
		});

		console.log(`Screenshot of element "${selector}" saved to ${outputPath}`);

	} catch (error) {
		console.error('Error taking screenshot:', error);
	} finally {
		if (browser) {
			await browser.close();
		}
	}
}

const args = process.argv.slice(2); // Slice to remove node executable and script path

if (args.length !== 2) {
	console.error('Usage: node screenshot.js <url> <outputPath>');
	process.exit(1);
}

const url = args[0];
const outputPath = args[1];

// Call the screenshot function with the provided arguments
screenshotContainer(url, outputPath);
