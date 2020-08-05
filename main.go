package main

import (
	"github.com/gin-gonic/gin"
)

func main() {
	router := gin.Default()
	router.GET("/", func(c *gin.Context) {
		c.JSON(200, TestJson{Response: "Hello World !!"})
	})
	router.GET("/:text", func(c *gin.Context) {
		text := c.Param("text")
		c.JSON(200, TestJson{Response: text})
	})
	router.Run()
}

type TestJson struct {
	Response interface{} `json:"response"`
}
