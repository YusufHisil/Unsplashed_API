import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'clickable_text.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController controller = ScrollController();
  final List<Photo> items = <Photo>[];
  final List<int> selected = <int>[];
  bool isLoading = true;
  String accessKey = '5oO8eQO-8LrF-WyrhC1T-RBfttwD0A72-9n8qe3ie14';
  int pageIdx = 1;
  String query = '';
  String color = '';
  bool colorMenuVisibility = false;

  @override
  void initState() {
    super.initState();
    controller.addListener(onScroll);
    loadItems();
  }

  Future<void> loadItems() async {
    setState(() => isLoading = true);
    final Client client = Client();

    final Uri uri = Uri(
      scheme: 'https',
      host: 'api.unsplash.com',
      pathSegments: createPath(),
      queryParameters: <String, String>{
        'client_id': accessKey,
        'page': pageIdx.toString(),
        'per-page': '30',
        if (query.isNotEmpty) 'query': query,
        if (color.isNotEmpty) 'color': color
      },
    );

    final Response response = await client.get(uri);
    dynamic body;

    if (query.isNotEmpty) {
      pageIdx = 1;
      items.clear();
      final Map<String, dynamic> b = jsonDecode(response.body) as Map<String, dynamic>;
      body = b['results'] as List<dynamic>;
    } else {
      body = jsonDecode(response.body) as List<dynamic>;
    }

    for (final dynamic item in body as List<dynamic>) {
      items.add(Photo(item as Map<String, dynamic>));
    }
    pageIdx++;
    await Future<void>.delayed(const Duration(seconds: 2));
    setState(() => isLoading = false);
  }

  void onScroll() {
    final double offset = controller.offset;
    final double maxExtent = controller.position.maxScrollExtent;

    if (!isLoading && offset > maxExtent * 0.5) {
      loadItems();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  List<String> createPath() {
    if (query.isNotEmpty) {
      return <String>['search', 'photos'];
    } else {
      return <String>['photos'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: const Text('Unsplashed Photos'),
            centerTitle: true,
            backgroundColor: Colors.blue,
            leading: IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_outlined, color: Colors.white),
                onPressed: () {
                  setState(() => colorMenuVisibility = !colorMenuVisibility);
                  if (!colorMenuVisibility) {
                    color = '';
                  }
                })),
        body: Column(
          children: <Widget>[
            Visibility(
              visible: colorMenuVisibility,
              child: SizedBox(
                height: 30.0,
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: colors.length,
                    itemBuilder: (BuildContext context, int index) {
                      return GestureDetector(
                          onTap: () {
                            setState(() => color = colors[index][0] as String);
                            loadItems();
                          },
                          child: Card(
                              margin: const EdgeInsets.all(8.0),
                              child: Container(
                                  width: 15.0,
                                  decoration: BoxDecoration(
                                    color: colors[index][1] as Color,
                                    border: Border.all(),
                                  ))));
                    }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: const InputDecoration(hintText: 'search'),
                onChanged: (String value) {
                  query = value;
                  items.clear();
                  loadItems();
                },
              ),
            ),
            Expanded(
              child: CustomScrollView(controller: controller, slivers: <Widget>[
                if (items.isEmpty)
                  const SliverToBoxAdapter(
                    child: Center(child: Text('no items found')),
                  ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
                    final Photo pht = items[index];
                    return Column(
                      children: <Widget>[
                        Image.network(pht.imgUrl,
                            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) {
                            // Image is fully loaded, return the actual image.
                            return child;
                          } else {
                            // Image is still loading, return a placeholder or loading indicator.
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                    : null,
                              ),
                            );
                          }
                        }),
                        ListTile(
                          title: Row(
                            children: <Widget>[
                              Expanded(
                                  child:
                                      ClickableText(text: '${pht.getArtist()}: ${pht.getSlug()}', url: pht.getUrl())),
                              const Icon(Icons.favorite, color: Colors.pink, size: 24),
                              Text(pht.likes.toString())
                            ],
                          ),
                          //Text('${pht.getArtist()}: ${pht.getSlug()}')
                          subtitle: Text(pht.getDesc()),
                        ),
                      ],
                    );
                  }, childCount: items.length),
                ),
                if (isLoading)
                  const SliverToBoxAdapter(
                      child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  ))
              ]),
            ),
          ],
        ));
  }
}

class Photo {
  Photo(Map<String, dynamic> json)
      : slug = json['slug'] as String,
        description = json['description'] as String?,
        likes = json['likes'] as int,
        imgUrl = (json['urls'] as Map<String, dynamic>)['small'] as String,
        artist = (json['user'] as Map<String, dynamic>)['name'] as String?,
        artistLink = ((json['user'] as Map<String,dynamic>)
        ['links'] as Map<String,dynamic>)
        ['html'] as String;

  final String slug;
  final String? description;
  final int likes;
  final String imgUrl;
  final String? artist;
  final String? artistLink;

  String getSlug() {
    if (slug.length >= 12) {
      return slug.substring(0, slug.length - 12);
    } else {
      return slug;
    }
  }

  String getDesc() {
    return description ?? '';
  }

  String getArtist() {
    return artist ?? '<artist>';
  }

  Uri getUrl() {
    return Uri.parse(artistLink ?? '');
  }
}

const List<List<dynamic>> colors = <List<dynamic>>[
  <dynamic>['black_and_white', Colors.grey],
  <dynamic>['black', Colors.black],
  <dynamic>['white', Colors.white],
  <dynamic>['yellow', Colors.yellow],
  <dynamic>['orange', Colors.orange],
  <dynamic>['red', Colors.red],
  <dynamic>['purple', Colors.purple],
  <dynamic>['magenta', Colors.pinkAccent],
  <dynamic>['green', Colors.green],
  <dynamic>['teal', Colors.teal],
  <dynamic>['blue', Colors.blue]
];
