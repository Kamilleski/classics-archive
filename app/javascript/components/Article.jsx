import React from 'react';
import Tag from './Tag';

export default class Article extends React.Component {
  render() {
    const article = this.props.article
    const fullName = `${article.author_first_name} ${article.author_last_name}`
    const imageTitle = `${article.title} by ${fullName}`
    const tags = article.tags.map(t => t.name).join(",")
    const date = new Date(article.featured_date).toLocaleDateString("en-US", { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })
    const featured = article.featured ? <div className="ribbon ribbon-top-right"><span title={'article featured ' + date }>Featured</span></div> : ''
    return (
      <div className="card full-card" data-item-tags={tags}>
        {featured}
        <a href={article.url} className="external-link" target="_blank">
          <img
            className="card-img-top"
            src={article.image.replace('original', 'card_top')}
            alt={imageTitle}
          />
        </a>
        <div>
          <div className="card-header">
            <a href={article.url} className="link-body" target="_blank">
              <h4 className="card-title link-body">
                {article.title}
                <br />
              </h4>
            </a>
            <label className="author">
              <input
                className="link-body"
                type="radio"
                name="filterrific[by_author]"
                value={article.author_first_name + ' ' + article.author_last_name}
                id={"filterrific_by_author_" + article.author_first_name + ' ' + article.author_last_name}
                autoComplete="off"
                style={{ appearance: 'none', display: 'none' }}>
              </input>
              by {' '}
              <b>
                {article.author_first_name} {article.author_last_name}
              </b>
              {' '}
              <i className="fa fa-user-circle author" aria-hidden="true"></i>
            </label>
            <br />
            <a className="published_time">
              {'on '}
              {article.pretty_date}
            </a>
            <p className="card-text link-body">
              <a href={article.url} className="link-body" target="_blank">
                {article.description}
                {' '}
                <span className="glyphicon glyphicon-book" aria-hidden="true">
                  <i className="fa fa-external-link" aria-hidden="true"></i>
                </span>
              </a>
            </p>
          </div>
          <div className="card-block inline">
            {article.tags.map(tag =>
              <Tag
                key={tag.name + '_' + article.id}
                tag={tag}
              />
            )}
          </div>
          <div className="card-footer">
            <a href={`http://www.web.archive.org${article.wayback_id}`} target="_blank"  className="permanent-link">
              <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/0/01/Wayback_Machine_logo_2010.svg/320px-Wayback_Machine_logo_2010.svg.png" />
              {' '}
              <i className="fa fa-institution" aria-hidden="true"></i>
            </a>
            <label className="site_name pull-right">
              <i className="fa fa-newspaper-o site_name" aria-hidden="true"></i>
              {' '}
              <input
                className="link-body"
                type="radio"
                name="filterrific[published_by]"
                value={article.site_name}
                id={"filterrific_published_by_" + this.props.article.site_name }
                autoComplete="off"
                style={{ appearance: 'none', display: 'none' }}>
              </input>
              {article.site_name}
            </label>
          </div>
        </div>
      </div>
    )
  }
}
