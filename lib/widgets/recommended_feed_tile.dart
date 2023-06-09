import 'package:becapy/providers/UserProvider.dart';
import 'package:becapy/widgets/tag_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/models/post.dart';

class RecommededFeedTile extends StatelessWidget {
  final Post post;
  const RecommededFeedTile(this.post, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final UserProvider userProvider =
        Provider.of<UserProvider>(context, listen: false);
    return Container(
      margin: const EdgeInsets.only(right: 30),
      width: 260,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 5,
            spreadRadius: 0.5,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(post.author!["profileURL"]),
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
                    post.author!["username"],
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: "Quicksand",
                    ),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    "${post.timeReadCalc()} mins read",
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
          Text(
            post.title ?? "",
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.5,
              fontFamily: "Quicksand",
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TagWidget(
                tag: post.tag!,
                canAdd: !userProvider.getUser()!.interests!.contains(post.tag!),
                tapHandler: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
