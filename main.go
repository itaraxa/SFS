package main

import (
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"path/filepath"

	log "github.com/sirupsen/logrus"
	"github.com/urfave/cli/v2"
)

func makeApp() *cli.App {
	return &cli.App{
		Name:        "Simple file server",
		Description: "Simple file server via http proto",
		Commands: []*cli.Command{
			{
				Name:    "start",
				Usage:   "start simple file server",
				Aliases: []string{"run", "s"},
				Action:  startFileServer,
				Flags: []cli.Flag{
					&cli.StringFlag{Name: "dir", Value: ".", Usage: "Set root directory for server"},
					&cli.StringFlag{Name: "port", Value: "9999", Usage: "Listening port"},
				},
			},
		},
	}
}

func startFileServer(c *cli.Context) (err error) {
	logger := log.New()
	logger.SetOutput(os.Stdout)

	port := fmt.Sprintf(":%s", c.String("port"))

	logger.Info("press Ctrl + C for exit")
	logger.Infof("start server on the port %s", c.String("port"))

	dir := c.String("dir")

	// check and resolve path to served directory
	filaPathAbs, err := filepath.Abs(c.String("dir"))
	if err != nil {
		logger.Errorf("cannot resolve directory: %s", c.String("dir"))
		return err
	}
	logger.Infof("server work in the directory: %s", filaPathAbs)

	// Ctrl+C handling
	signalChan := make(chan os.Signal, 1)
	signal.Notify(signalChan, os.Interrupt)
	go func() {
		<-signalChan
		logger.Info("Exit programm")
		os.Exit(0)
	}()

	// create and start FileServer handler
	handler := http.FileServer(http.Dir(dir))
	if err = http.ListenAndServe(port, handler); err != nil {
		logger.WithFields(log.Fields{"APP": os.Args[0],
			"port":      c.String("port"),
			"directory": c.String("dir")}).Error("start server error")
	}

	return err
}

func main() {
	app := makeApp()
	if err := app.Run(os.Args); err != nil {
		fmt.Printf("\nCritical error: Cannot start application: %v\n", err)
	}
}
