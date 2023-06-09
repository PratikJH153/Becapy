import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '/screens/HomePage.dart';
import '/screens/post/CommentPage.dart';
import '/widgets/ask_dialog_widget.dart';
import '/widgets/tag_widget.dart';
import '/helper/GlobalFunctions.dart';
import '/helper/backend/database.dart';
import '/helper/backend/apis.dart';
import '/providers/CurrentPostProvider.dart';
import '/providers/UserProvider.dart';
import '/helper/utils/loader.dart';
import '/models/post.dart';
import '/widgets/constants.dart';
import '/widgets/recommended_feed_tile.dart';
import '/widgets/upper_widget_bottom_sheet.dart';

class ViewPostPage extends StatefulWidget {
  final Post thePost;

  const ViewPostPage(this.thePost, {Key? key}) : super(key: key);

  @override
  State<ViewPostPage> createState() => _ViewPostPageState();
}

class _ViewPostPageState extends State<ViewPostPage> {
  bool isAddingInterests = false;
  bool isDeleting = false;

  _ProfileRow() => Row(
        children: [
          SizedBox(
            height: 40,
            width: 40,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: FadeInImage.assetNetwork(
                placeholder: "assets/images/placeholder.jpg",
                image: widget.thePost.author!["profileURL"],
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(
            width: 15,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.thePost.author!["username"],
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: "Quicksand",
                ),
              ),
              const SizedBox(
                height: 3,
              ),
              Text(
                timeago.format(
                  DateTime.parse(widget.thePost.createdAt!),
                ),
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      );

  _TitleDescriptionSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            widget.thePost.title!.toString(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              height: 1.5,
              fontFamily: "Ubuntu",
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          if (widget.thePost.desc != null && widget.thePost.desc!.trim() != "")
            SelectableText(
              widget.thePost.desc!,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.grey[800],
                fontFamily: "Raleway",
              ),
            ),
        ],
      );

  _ReccomendedPostsSection(
      {required List posts, required bool wentWrong, required bool isLoading}) {
    String currPostUserID = widget.thePost.author!["_id"];

    List filtered = [];

    for (int i = 0; i < posts.length; i++) {
      print(posts[i]);
      bool isAuthorNull = posts[i]["author"] == null;
      bool isSameUser = true;
      if (!isAuthorNull) {
        if (posts[i]["author"] != currPostUserID) {
          isSameUser = false;
        }
      }
      if (!isSameUser && !isAuthorNull) {
        filtered.add(posts[i]);
      }
    }

    posts = filtered;

    return SizedBox(
      height: 230,
      child: wentWrong
          ? const Text("Couldn't fetch Posts")
          : isLoading
              ? const GlobalLoader()
              : posts.isEmpty
                  ? const Text("No Related Posts Found.")
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                        bottom: 30,
                      ),
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      itemCount: posts.length,
                      itemBuilder: (ctx, index) {
                        Post post = Post.fromJson(posts[index]);
                        bool isTheSamePostAsCurrent =
                            post.postID == widget.thePost.postID;

                        return isTheSamePostAsCurrent && posts.length == 1
                            ? const Text("No Related Posts Found.")
                            : post.author != null &&
                                    post.title != null &&
                                    post.desc != null
                                ? GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (ctx) => ViewPostPage(post),
                                        ),
                                      );
                                    },
                                    child: RecommededFeedTile(post),
                                  )
                                : const SizedBox();
                      },
                    ),
    );
  }

  Future<void> _initialize() async {
    final CurrentPostProvider currentPost =
        Provider.of<CurrentPostProvider>(context, listen: false);
    final UserProvider userProvider =
        Provider.of<UserProvider>(context, listen: false);

    currentPost.resetRelatedPosts();

    final relatedPostsData = await PostAPIS.getRelatedPosts({
      "interest": widget.thePost.tag,
      "userID": userProvider.getUser()!.userID,
    });
    Map unpackedRelatedPostsData = unPackLocally(relatedPostsData);

    if (unpackedRelatedPostsData["success"] == 1) {
      currentPost.setRelatedPosts(unpackedRelatedPostsData["unpacked"]);
    } else {
      currentPost.toggleWentWrongRelated(true);
    }
  }

  @override
  void initState() {
    _initialize();
    super.initState();
  }

  /// DEPENDENCIES
  ///

  void addInterest(BuildContext context, String id, String tag) async {
    setState(() {
      isAddingInterests = true;
    });
    await addInterests(context, id, tag);
    setState(() {
      isAddingInterests = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // print("VIEW POST PAGE BUILD");
    CurrentPostProvider currentPost = Provider.of<CurrentPostProvider>(context);
    UserProvider userProvider =
        Provider.of<UserProvider>(context, listen: false);

    List relatedList = currentPost.relatedPost;

    bool isLoadedTrending = currentPost.isRelatedLoaded;
    bool wentWrongTrending = currentPost.wentWrongRelated;

    bool showDelete =
        userProvider.getUser()!.userID == widget.thePost.author!["_id"];

    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            UpperWidgetOfBottomSheet(
              backTapHandler: () {
                Navigator.of(context).pop();
              },
              tapHandler: () async {
                await showDialog(
                  context: context,
                  builder: (ctx) => AskDialogWidget(
                    tapHandler: () async {
                      await deletePost(context, widget.thePost);
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        HomePage.routeName,
                        (route) => false,
                      );
                    },
                    title: "Delete Post",
                    des: "Do you really want to delete your post?",
                  ),
                );
                setState(() {
                  isDeleting = false;
                });
              },
              toShow: showDelete,
              icon: Icons.delete,
              color: Colors.red[400],
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(
                  left: kLeftPadding,
                  right: kRightPadding,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: isDeleting
                      ? const Center(
                          child: GlobalLoader(),
                        )
                      : ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(top: 30),
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (widget.thePost.tag != null)
                                      isAddingInterests
                                          ? const GlobalLoader()
                                          : TagWidget(
                                              tag: widget.thePost.tag!,
                                              tapHandler: () {
                                                UserProvider userProvider =
                                                    Provider.of<UserProvider>(
                                                        context,
                                                        listen: false);
                                                addInterest(
                                                    context,
                                                    userProvider
                                                        .getUser()!
                                                        .userID!,
                                                    widget.thePost.tag!);
                                              },
                                              canAdd: !userProvider
                                                  .getUser()!
                                                  .interests!
                                                  .contains(
                                                      widget.thePost.tag!),
                                            ),
                                    Text(
                                      "${widget.thePost.timeReadCalc()} mins read",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 15,
                                ),
                                _ProfileRow(),
                                const SizedBox(
                                  height: 15,
                                ),
                                _TitleDescriptionSection(),
                                const SizedBox(
                                  height: 30,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    VoteSection(context, widget.thePost),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (ctx) => CommentPage(
                                              post: widget.thePost,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Icon(
                                        CupertinoIcons.chat_bubble_2,
                                        color: Colors.grey,
                                        size: 22,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 30,
                                ),
                                const Text(
                                  "Related Posts",
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                    color: Colors.black38,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: "Nunito",
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                _ReccomendedPostsSection(
                                  posts: relatedList,
                                  wentWrong: wentWrongTrending,
                                  isLoading: !isLoadedTrending,
                                )
                              ],
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
