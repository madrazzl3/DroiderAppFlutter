import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/HtmlParser.dart';
import 'package:flutter_native_web/flutter_native_web.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;

void main() => runApp(new MyApp());
const articleScreen = "article";
Map<String, String> urlToHtml = new Map();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Droider List',
      theme: new ThemeData(
        primarySwatch: Colors.orange,
        primaryColorBrightness: Brightness.dark,
      ),
      home: new FeedPage(title: 'Droider'),
    );
  }
}

class FeedPage extends StatefulWidget {
  FeedPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _FeedPageState createState() => new _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List items;
  final htmlUnEscape = new HtmlUnescape();

  Future<Null> _loadData() async {
    var link = Uri.parse(
        'http://droider.ru/wp-content/themes/droider/feed.php?category=0&slug=main&count=12&offset=0');

    var response = await http.get(link);
    Map data = json.decode(response.body);
    setState(() {
      items = data['posts'];
    });
    print(items.toString());
  }

  @override
  void initState() {
    _loadData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text(widget.title)),
      body: new RefreshIndicator(
          child: new ListView.builder(
              itemCount: items == null ? 0 : items.length,
              itemBuilder: cardItemBuilder),
          onRefresh: _loadData),
    );
  }

  Widget cardItemBuilder(context, index) {
    final title = htmlUnEscape.convert(items[index]['title']);
    final cardImageUrl = items[index]['picture_wide'];
    final articleImageUrl = items[index]['picture_basic'];
    final articleUrl = items[index]['url'];

    return new GestureDetector(
        onTap: () {
          Route route = new MaterialPageRoute(
              builder: (BuildContext context) =>
                  new Article(title, articleImageUrl, articleUrl));
          Navigator.of(context).push(route);
        },
        child: new Padding(
            padding: new EdgeInsets.all(8.0),
            child: new Card(
                child: new Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    new CachedNetworkImage(
                      imageUrl: cardImageUrl,
                      placeholder: new CircularProgressIndicator(),
                      errorWidget: new Icon(Icons.error),
                    ),
                    new Padding(
                      padding: EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 16.0),
                      child: new Text(title,
                          softWrap: false,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          style: new TextStyle(fontWeight: FontWeight.bold)
                      ),
                    )
                  ],
            ))));
  }
}

class Article extends StatefulWidget {
  final imageUrl;
  final title;
  final articleUrl;

  Article(this.title, this.imageUrl, this.articleUrl);

  @override
  _ArticleState createState() => new _ArticleState();
}

class _ArticleState extends State<Article> {
  String articleHtml = "";

  loadArticle(String url) async {
    var response = await http.get(url);
    setState(() {
      articleHtml = new HtmlParser(response.body).parseHtml();
      urlToHtml[widget.articleUrl] = articleHtml;
    });
  }

  void _onWebCreated(WebController webController) {
    print("inside initializer");
    webController.loadData(articleHtml);
  }

  @override
  void initState() {
    if (urlToHtml.containsKey(widget.articleUrl)) {
      articleHtml = urlToHtml[widget.articleUrl];
    } else {
      loadArticle(widget.articleUrl);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(title: new Text(widget.title)),
        body: new Container(
            constraints: BoxConstraints.expand(),
            child: new FlutterNativeWeb(onWebCreated: _onWebCreated)
        )
    );
  }
}
