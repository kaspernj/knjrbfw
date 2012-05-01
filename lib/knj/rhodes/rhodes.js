function knj_rhodes_html_links(args){
	$.ajax({type: "POST", data: {"url": args.url}, url: "/app/Knj/html_links"})
}

function knj_rhodes_youtube_open_in_app(args){
	$.ajax({type: "POST", data: {"youtube_id": args.youtube_id}, url: "/app/Knj/youtube_open_in_app"})
}