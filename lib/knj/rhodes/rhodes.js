function knj_rhodes_html_links(args){
	$.ajax({type: "POST", data: {"url": args["url"]}, url: "/app/Knj/html_links"});
}