package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"os"

	"github.com/chromedp/chromedp"
)

func main() {
	// create context
	ctx, cancel := chromedp.NewContext(
		context.Background(),
	)
	defer cancel()

	// capture screenshot of an element
	var buf []byte

	var filepath string
	flag.StringVar(&filepath, "file", "", "Path to the HTML file")
	flag.Parse()

	if filepath == "" {
		log.Fatal("Error: --file argument is required")
	}

	urlstr := fmt.Sprintf("file://%s", filepath)
	fmt.Printf("urlstr: %s\n", urlstr)

	// capture entire browser viewport, returning png with quality=90
	if err := chromedp.Run(ctx, elementScreenshot(urlstr, `div.container`, &buf)); err != nil {
		log.Fatal(err)
	}
	if err := os.WriteFile("screenshot.png", buf, 0o644); err != nil {
		log.Fatal(err)
	}
}

// elementScreenshot takes a screenshot of a specific element.
func elementScreenshot(urlstr, sel string, res *[]byte) chromedp.Tasks {
	return chromedp.Tasks{
		chromedp.Navigate(urlstr),
		chromedp.Screenshot(sel, res, chromedp.NodeVisible),
	}
}
